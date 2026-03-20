{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.TaskSQLServer
  ( runTaskRepo,
  )
where

import App.Domain.Task.Entity (Task (..), TaskPriority (..), TaskStatus (..))
import App.Domain.Task.Repository (TaskRepo (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Database.MSSQLServer.Query (sql)
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
--     -> Eff (TaskRepo : es) a   -- TaskRepo を含むスタック
--     -> Eff es a                -- TaskRepo を除いたスタック
runTaskRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  Eff (TaskRepo : es) a ->
  Eff es a
runTaskRepo pool = interpret $ \_ -> \case
  GetTask ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        sql conn "SELECT TOP 1 id, userId, title, description, status, priority, dueDate, createdAt, updatedAt FROM testdb.dbo.TASKS" ::
          IO [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)]
      let (tid, uid, title, desc, status, priority, dueDate, createdAt, updatedAt) = head rows
      return $
        Task
          tid
          uid
          title
          (fromMaybe "" desc)
          (parseStatus status)
          (parsePriority priority)
          (fromMaybe "" dueDate)
          createdAt
          updatedAt
  GetTaskAll ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        sql conn "SELECT id, userId, title, description, status, priority, dueDate, createdAt, updatedAt FROM testdb.dbo.TASKS" ::
          IO [(Int, Int, Text, Maybe Text, Text, Text, Maybe Text, Text, Text)]
      return $
        map
          ( \(tid, uid, title, desc, status, priority, dueDate, createdAt, updatedAt) ->
              Task
                tid
                uid
                title
                (fromMaybe "" desc)
                (parseStatus status)
                (parsePriority priority)
                (fromMaybe "" dueDate)
                createdAt
                updatedAt
          )
          rows
  PostTask ->
    liftIO $ withMSSQLConn pool $ \_ -> do
      return $ Task 0 1 "新しいタスク" "説明" Todo Medium "2026-03-20" "2026-03-19T00:00:00Z" "2026-03-19T00:00:00Z"
