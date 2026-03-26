{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.HabitSQLServer
  ( runHabitRepo,
  )
where

import App.Domain.Auth.Entity (User (..), UserId (..))
import App.Domain.HabitTracker.Entity (Habit (..))
import App.Domain.HabitTracker.Operation (CreateHabit (..))
import App.Domain.HabitTracker.Repository (HabitRepo (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import Database.MSSQLServer.Query (sql)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

runHabitRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  User ->
  Eff (HabitRepo : es) a ->
  Eff es a
runHabitRepo pool user = interpret $ \_ -> \case
  CreateHabitOp (CreateHabit hTitle hDesc hColor hCategory) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId (userUserId user)
          esc = T.replace "'" "''"
          insertSql =
            "INSERT INTO testdb.dbo.HABITS (userId, title, description, color, category) "
              <> "OUTPUT INSERTED.id, INSERTED.title, INSERTED.description, INSERTED.color, INSERTED.category, INSERTED.createdAt, INSERTED.updatedAt "
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
              <> "')"
      rows <-
        sql conn insertSql ::
          IO [(Int, Text, Text, Text, Text, UTCTime, UTCTime)]
      let (rowId, title, desc, color, category, createdAt, updatedAt) = head rows
      return
        Habit
          { habitId = rowId,
            habitTitle = title,
            habitDescription = desc,
            habitColor = color,
            habitCategory = category,
            habitCurrentStreak = 0,
            habitBestStreak = 0,
            habitTotalCompletions = 0,
            habitTodayCompleted = False,
            habitCreatedAt = createdAt,
            habitUpdatedAt = updatedAt
          }
  GetHabitAll ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId (userUserId user)
      print uid
      rows <-
        sql conn ("SELECT id, title, description, color, category, currentStreak, bestStreak, totalCompletions, todayCompleted, createdAt, updatedAt FROM testdb.dbo.HABITS WHERE userId = " <> T.pack (show uid)) ::
          IO [(Int, Text, Text, Text, Text, Int, Int, Int, Bool, UTCTime, UTCTime)]
      print rows
      return $
        map
          ( \(hid, htitle, hdesc, hcolor, hcat, hcur, hbest, htotal, htoday, hcreated, hupdated) ->
              Habit
                { habitId = hid,
                  habitTitle = htitle,
                  habitDescription = hdesc,
                  habitColor = hcolor,
                  habitCategory = hcat,
                  habitCurrentStreak = hcur,
                  habitBestStreak = hbest,
                  habitTotalCompletions = htotal,
                  habitTodayCompleted = htoday,
                  habitCreatedAt = hcreated,
                  habitUpdatedAt = hupdated
                }
          )
          rows
