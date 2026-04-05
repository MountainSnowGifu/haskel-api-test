{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.HabitTracker.HabitSQLServer
  ( runHabitRepo,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..), CreateHabitLogCommand (..), UpdateHabitCommand (..))
import App.Application.HabitTracker.Repository (HabitRepo (..))
import App.Domain.Auth.Entity (UserId (..))
import App.Domain.HabitTracker.Entity (Habit (..), HabitLog (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (Day, UTCTime (..))
import Data.Time.Format (defaultTimeLocale, parseTimeM)
import Database.MSSQLServer.Query (Only (..), sql)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

runHabitRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  UserId ->
  Eff (HabitRepo : es) a ->
  Eff es a
runHabitRepo pool authUserId = interpret $ \_ -> \case
  CreateHabitOp (CreateHabitCommand hTitle hDesc hColor hCategory) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
          esc = T.replace "'" "''"
          insertSql =
            "INSERT INTO testdb.dbo.HABITS (user_id, title, description, color, category, created_at, updated_at) "
              <> "OUTPUT INSERTED.id, INSERTED.title, INSERTED.description, INSERTED.color, INSERTED.category, INSERTED.created_at, INSERTED.updated_at "
              <> "VALUES ("
              <> T.pack (show uid)
              <> ", N'"
              <> esc hTitle
              <> "', N'"
              <> esc hDesc
              <> "', N'"
              <> esc hColor
              <> "', N'"
              <> esc hCategory
              <> "', SYSDATETIME(), SYSDATETIME())"
      rows <-
        sql conn insertSql ::
          IO [(Int, Text, Text, Text, Text, UTCTime, UTCTime)]
      case rows of
        [] -> return Nothing
        (rowId, title, desc, color, category, createdAt, updatedAt) : _ ->
          return $
            Just
              Habit
                { habitId = rowId,
                  habitTitle = title,
                  habitDescription = desc,
                  habitColor = color,
                  habitCategory = category,
                  habitCreatedAt = createdAt,
                  habitUpdatedAt = updatedAt
                }
  UpdateHabitOp hid (UpdateHabitCommand _ hTitle hDesc hColor hCategory) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
          esc = T.replace "'" "''"
          updateSql =
            "UPDATE testdb.dbo.HABITS SET "
              <> "title = N'"
              <> esc hTitle
              <> "', description = N'"
              <> esc hDesc
              <> "', color = N'"
              <> esc hColor
              <> "', category = N'"
              <> esc hCategory
              <> "', updated_at = SYSDATETIME() "
              <> "OUTPUT INSERTED.id, INSERTED.title, INSERTED.description, INSERTED.color, INSERTED.category, INSERTED.created_at, INSERTED.updated_at "
              <> "WHERE id = "
              <> T.pack (show hid)
              <> " AND user_id = "
              <> T.pack (show uid)
      rows <-
        sql conn updateSql ::
          IO [(Int, Text, Text, Text, Text, UTCTime, UTCTime)]
      case rows of
        [] -> return Nothing
        (rowId, title, desc, color, category, createdAt, updatedAt) : _ ->
          return $
            Just
              Habit
                { habitId = rowId,
                  habitTitle = title,
                  habitDescription = desc,
                  habitColor = color,
                  habitCategory = category,
                  habitCreatedAt = createdAt,
                  habitUpdatedAt = updatedAt
                }
  DeleteHabitOp hid ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
          deleteSql =
            "DELETE FROM testdb.dbo.HABITS OUTPUT DELETED.id WHERE id = "
              <> T.pack (show hid)
              <> " AND user_id = "
              <> T.pack (show uid)
      rows <- sql conn deleteSql :: IO [Only Int]
      return (not (null rows))
  CreateHabitLogOp hid (CreateHabitLogCommand _ status) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
          esc = T.replace "'" "''"
      -- habit_id が自分の habit であることを確認してから INSERT
      ownerRows <-
        sql conn ("SELECT id FROM testdb.dbo.HABITS WHERE id = " <> T.pack (show hid) <> " AND user_id = " <> T.pack (show uid)) ::
          IO [Only Int]
      case ownerRows of
        [] -> return Nothing
        _ -> do
          let insertSql =
                "INSERT INTO testdb.dbo.habit_logs (habit_id, date, status, note, created_at) "
                  <> "VALUES ("
                  <> T.pack (show hid)
                  <> ", CAST(SYSDATETIME() AS DATE), N'"
                  <> esc status
                  <> "', N'', SYSDATETIME())"
          _ <- sql conn insertSql :: IO ()
          return (Just ())
  GetHabitsOp ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      habitRows <-
        sql
          conn
          ( "SELECT id, title, description, color, category, created_at, updated_at "
              <> "FROM testdb.dbo.HABITS "
              <> "WHERE user_id = "
              <> T.pack (show uid)
          ) ::
          IO [(Int, Text, Text, Text, Text, UTCTime, UTCTime)]
      logRows <-
        sql
          conn
          ( "SELECT l.habit_id, CONVERT(NVARCHAR(10), l.date, 23), l.status "
              <> "FROM testdb.dbo.habit_logs l "
              <> "INNER JOIN testdb.dbo.HABITS h ON l.habit_id = h.id "
              <> "WHERE h.user_id = "
              <> T.pack (show uid)
              <> " ORDER BY l.habit_id, l.date"
          ) ::
          IO [(Int, Text, Text)]
      return $ map (buildHabit logRows) habitRows
  where
    parseDay :: Text -> Maybe Day
    parseDay = parseTimeM True defaultTimeLocale "%Y-%m-%d" . T.unpack

    -- DB から取得した生データを (Habit, [HabitLog]) に変換する。
    -- ストリーク計算は行わない。Application 層の責務。
    buildHabit ::
      [(Int, Text, Text)] ->
      (Int, Text, Text, Text, Text, UTCTime, UTCTime) ->
      (Habit, [HabitLog])
    buildHabit logRows (hid, htitle, hdesc, hcolor, hcat, hcreated, hupdated) =
      let habitLogs =
            [ HabitLog 0 lid day status "" (UTCTime day 0)
              | (lid, dateText, status) <- logRows,
                lid == hid,
                Just day <- [parseDay dateText]
            ]
          habit =
            Habit
              { habitId = hid,
                habitTitle = htitle,
                habitDescription = hdesc,
                habitColor = hcolor,
                habitCategory = hcat,
                habitCreatedAt = hcreated,
                habitUpdatedAt = hupdated
              }
       in (habit, habitLogs)
