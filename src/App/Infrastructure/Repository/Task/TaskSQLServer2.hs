{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.Task.TaskSQLServer2
  ( runTaskRepo2,
  )
where

import App.Application.Task.Command (CreateTaskCommand (..), PatchTaskCommand (..), TaskStatusChanged (..), UpdateTaskCommand (..))
import App.Application.Task.Repository (TaskRepo (..))
import App.Domain.Auth.Entity (User (..), UserId (..))
import App.Domain.Task.Entity (Task (..), TaskPriority (..), TaskStatus (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Database.MSSQLServer.Query (Only (..), RpcQuery (..), RpcResponse (..), StoredProcedure (..), intVal, nvarcharVal, rpc, withTransaction)
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
--     -> User                -- 認証済みユーザー
--     -> Eff (TaskRepo : es) a   -- TaskRepo を含むスタック
--     -> Eff es a                -- TaskRepo を除いたスタック
runTaskRepo2 ::
  (IOE :> es) =>
  MSSQLPool ->
  User ->
  Eff (TaskRepo : es) a ->
  Eff es a
runTaskRepo2 pool user = interpret $ \_ -> \case
  GetTaskOp tid ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "SELECT id, userId, title, description, status, priority, dueDate, createdAt, updatedAt FROM testdb.dbo.TASKS_NEW WHERE id = @Id"),
                nvarcharVal "" (Just "@Id int"),
                intVal "@Id" (Just tid)
              )
          ) ::
          IO (RpcResponse () [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)])
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
      let uid = unUserId (userUserId user)
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "SELECT id, userId, title, description, status, priority, dueDate, createdAt, updatedAt FROM testdb.dbo.TASKS_NEW WHERE userId = @UserId"),
                nvarcharVal "" (Just "@UserId int"),
                intVal "@UserId" (Just uid)
              )
          ) ::
          IO (RpcResponse () [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)])
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
      let uid = unUserId (userUserId user)
          status = T.pack (show tStatus)
          priority = T.pack (show tPriority)
      withTransaction conn $ do
        RpcResponse _ _ rows <-
          rpc
            conn
            ( RpcQuery
                SP_ExecuteSql
                ( nvarcharVal "" (Just "INSERT INTO testdb.dbo.TASKS_NEW (userId, title, description, status, priority, dueDate, createdAt, updatedAt) OUTPUT INSERTED.id, INSERTED.userId, INSERTED.title, INSERTED.description, INSERTED.status, INSERTED.priority, INSERTED.dueDate, INSERTED.createdAt, INSERTED.updatedAt VALUES (@UserId, @Title, @Desc, @Status, @Priority, @DueDate, @CreatedAt, @UpdatedAt)"),
                  nvarcharVal "" (Just "@UserId int, @Title nvarchar(max), @Desc nvarchar(max), @Status nvarchar(50), @Priority nvarchar(50), @DueDate nvarchar(50), @CreatedAt nvarchar(50), @UpdatedAt nvarchar(50)"),
                  intVal "@UserId" (Just uid),
                  nvarcharVal "@Title" (Just tTitle),
                  nvarcharVal "@Desc" (Just tDesc),
                  nvarcharVal "@Status" (Just status),
                  nvarcharVal "@Priority" (Just priority),
                  nvarcharVal "@DueDate" (Just tDueDate),
                  nvarcharVal "@CreatedAt" (Just tCreatedAt),
                  nvarcharVal "@UpdatedAt" (Just tUpdatedAt)
                )
            ) ::
            IO (RpcResponse () [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)])
        let (rowId, rUid, title, desc, sts, pri, dueDate, createdAt, updatedAt) = head rows
        _ <-
          ( rpc
              conn
              ( RpcQuery
                  SP_ExecuteSql
                  ( nvarcharVal "" (Just "INSERT INTO testdb.dbo.LOGS (logid) OUTPUT INSERTED.logid VALUES (@LogId)"),
                    nvarcharVal "" (Just "@LogId int"),
                    intVal "@LogId" (Just rowId)
                  )
              ) ::
              IO (RpcResponse () [Only Int])
            )
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
      let status = T.pack (show uStatus)
          priority = T.pack (show uPriority)
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "UPDATE testdb.dbo.TASKS_NEW SET title = @Title, description = @Desc, status = @Status, priority = @Priority, dueDate = @DueDate, updatedAt = GETDATE() OUTPUT INSERTED.id, INSERTED.userId, INSERTED.title, INSERTED.description, INSERTED.status, INSERTED.priority, INSERTED.dueDate, INSERTED.createdAt, INSERTED.updatedAt WHERE id = @Id"),
                nvarcharVal "" (Just "@Title nvarchar(max), @Desc nvarchar(max), @Status nvarchar(50), @Priority nvarchar(50), @DueDate nvarchar(50), @Id int"),
                nvarcharVal "@Title" (Just uTitle),
                nvarcharVal "@Desc" (Just uDesc),
                nvarcharVal "@Status" (Just status),
                nvarcharVal "@Priority" (Just priority),
                nvarcharVal "@DueDate" (Just uDueDate),
                intVal "@Id" (Just tid)
              )
          ) ::
          IO (RpcResponse () [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)])
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
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "UPDATE testdb.dbo.TASKS_NEW SET status = @Status, updatedAt = GETDATE() OUTPUT INSERTED.id, INSERTED.status, INSERTED.updatedAt WHERE id = @Id"),
                nvarcharVal "" (Just "@Status nvarchar(50), @Id int"),
                nvarcharVal "@Status" (Just statusText),
                intVal "@Id" (Just tid)
              )
          ) ::
          IO (RpcResponse () [(Int, Text, Text)])
      return $
        listToMaybe rows >>= \(rowId, sts, updatedAt) ->
          Just (TaskStatusChanged rowId (parseStatus sts) updatedAt)
  DeleteTaskOp tid ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "DELETE FROM testdb.dbo.TASKS_NEW OUTPUT DELETED.id, DELETED.userId WHERE id = @Id"),
                nvarcharVal "" (Just "@Id int"),
                intVal "@Id" (Just tid)
              )
          ) ::
          IO (RpcResponse () [(Int, Int)])
      return $ listToMaybe rows >> Just ()
