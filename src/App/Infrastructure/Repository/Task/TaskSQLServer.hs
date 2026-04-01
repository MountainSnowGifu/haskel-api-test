{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.Task.TaskSQLServer
  ( runTaskRepo,
  )
where

import App.Domain.Auth.Entity (UserId (..))
import App.Domain.Task.Entity (Task (..), TaskPriority (..), TaskStatus (..))
import App.Application.Task.Command (CreateTaskCommand (..), UpdateTaskCommand (..), PatchTaskCommand (..), TaskStatusChanged (..))
import App.Application.Task.Repository (TaskRepo (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Database.MSSQLServer.Query (Only (..), sql, withTransaction)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

parseStatus :: Text -> TaskStatus
parseStatus "InProgress" = InProgress
parseStatus "Done" = Done
parseStatus _ = Todo

parsePriority :: Text -> TaskPriority
parsePriority "Low" = Low
parsePriority "High" = High
parsePriority _ = Medium

-- | TaskRepo エフェクトを MSSQL で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es              -- IO を実行できるエフェクトが必要
--     => MSSQLPool           -- コネクションプール
--     -> UserId              -- 認証済みユーザーID
--     -> Eff (TaskRepo : es) a   -- TaskRepo を含むスタック
--     -> Eff es a                -- TaskRepo を除いたスタック
runTaskRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  UserId ->
  Eff (TaskRepo : es) a ->
  Eff es a
runTaskRepo pool authUserId = interpret $ \_ -> \case
  GetTaskOp tid ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        sql conn ("SELECT id, userId, title, description, status, priority, dueDate, createdAt, updatedAt FROM testdb.dbo.TASKS_NEW WHERE id = " <> T.pack (show tid)) ::
          IO [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)]
      return $
        listToMaybe rows >>= \(rowId, uid, title, desc, status, priority, dueDate, createdAt, updatedAt) ->
          Just $
            Task
              rowId
              uid
              title
              (fromMaybe "" desc)
              (parseStatus status)
              (parsePriority priority)
              (fromMaybe "" dueDate)
              createdAt
              updatedAt
  GetTasksOp ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      rows <-
        sql conn ("SELECT id, userId, title, description, status, priority, dueDate, createdAt, updatedAt FROM testdb.dbo.TASKS_NEW WHERE userId = " <> T.pack (show uid)) ::
          IO [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)]
      return $
        map
          ( \(tid, taskUid, title, desc, status, priority, dueDate, createdAt, updatedAt) ->
              Task
                tid
                taskUid
                title
                (fromMaybe "" desc)
                (parseStatus status)
                (parsePriority priority)
                (fromMaybe "" dueDate)
                createdAt
                updatedAt
          )
          rows
  CreateTaskOp (CreateTaskCommand tTitle tDesc tStatus tPriority tDueDate) tCreatedAt tUpdatedAt ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
          esc = T.replace "'" "''"
          status = T.pack (show tStatus)
          priority = T.pack (show tPriority)
          insertSql =
            "INSERT INTO testdb.dbo.TASKS_NEW (userId, title, description, status, priority, dueDate, createdAt, updatedAt) "
              <> "OUTPUT INSERTED.id, INSERTED.userId, INSERTED.title, INSERTED.description, INSERTED.status, INSERTED.priority, INSERTED.dueDate, INSERTED.createdAt, INSERTED.updatedAt "
              <> "VALUES ("
              <> T.pack (show uid)
              <> ", N'"
              <> esc tTitle
              <> "', N'"
              <> esc tDesc
              <> "', '"
              <> status
              <> "', '"
              <> priority
              <> "', '"
              <> esc tDueDate
              <> "', '"
              <> esc tCreatedAt
              <> "', '"
              <> esc tUpdatedAt
              <> "')"
      withTransaction conn $ do
        rows <-
          sql conn insertSql ::
            IO [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)]
        let (rowId, rUid, title, desc, sts, pri, dueDate, createdAt, updatedAt) = head rows
        _ <-
          sql conn ("INSERT INTO testdb.dbo.LOGS (logid) OUTPUT INSERTED.logid VALUES (" <> T.pack (show rowId) <> ")") ::
            IO [Only Int]
        return $
          Task
            rowId
            rUid
            title
            (fromMaybe "" desc)
            (parseStatus sts)
            (parsePriority pri)
            (fromMaybe "" dueDate)
            createdAt
            updatedAt
  ReplaceTaskOp tid (UpdateTaskCommand uTitle uDesc uStatus uPriority uDueDate) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let esc = T.replace "'" "''"
          status = T.pack (show uStatus)
          priority = T.pack (show uPriority)
          updateSql =
            "UPDATE testdb.dbo.TASKS_NEW "
              <> "SET title = N'"
              <> esc uTitle
              <> "', description = N'"
              <> esc uDesc
              <> "', status = '"
              <> status
              <> "', priority = '"
              <> priority
              <> "', dueDate = '"
              <> esc uDueDate
              <> "', updatedAt = GETDATE() "
              <> "OUTPUT INSERTED.id, INSERTED.userId, INSERTED.title, INSERTED.description, INSERTED.status, INSERTED.priority, INSERTED.dueDate, INSERTED.createdAt, INSERTED.updatedAt "
              <> "WHERE id = "
              <> T.pack (show tid)
      rows <-
        sql conn updateSql ::
          IO [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)]
      return $
        listToMaybe rows >>= \(rowId, rUid, title, desc, sts, pri, dueDate, createdAt, updatedAt) ->
          Just $
            Task
              rowId
              rUid
              title
              (fromMaybe "" desc)
              (parseStatus sts)
              (parsePriority pri)
              (fromMaybe "" dueDate)
              createdAt
              updatedAt
  ChangeTaskStatusOp tid (PatchTaskCommand pStatus) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let statusText = T.pack (show pStatus)
          patchSql =
            "UPDATE testdb.dbo.TASKS_NEW "
              <> "SET status = '"
              <> statusText
              <> "', updatedAt = GETDATE() "
              <> "OUTPUT INSERTED.id, INSERTED.status, INSERTED.updatedAt "
              <> "WHERE id = "
              <> T.pack (show tid)
      rows <-
        sql conn patchSql ::
          IO [(Int, Text, Text)]
      return $
        listToMaybe rows >>= \(rowId, sts, updatedAt) ->
          Just (TaskStatusChanged rowId (parseStatus sts) updatedAt)
  DeleteTaskOp tid ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        sql conn ("DELETE FROM testdb.dbo.TASKS_NEW OUTPUT DELETED.id, DELETED.userId WHERE id = " <> T.pack (show tid)) ::
          IO [(Int, Int)]
      return $ listToMaybe rows >> Just ()
