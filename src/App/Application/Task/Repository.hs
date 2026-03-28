{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Task.Repository
  ( TaskRepo (..),
    getTask,
    getTaskAll,
    createTask,
    replaceTask,
    changeTaskStatus,
    deleteTask,
  )
where

import App.Domain.Task.Entity (Task)
import App.Application.Task.Command (CreateTaskCommand, UpdateTaskCommand, PatchTaskCommand, TaskStatusChanged)
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data TaskRepo :: Effect where
  GetTaskOp :: Int -> TaskRepo m (Maybe Task)
  GetTasksOp :: TaskRepo m [Task]
  CreateTaskOp :: CreateTaskCommand -> Text -> Text -> TaskRepo m Task
  ReplaceTaskOp :: Int -> UpdateTaskCommand -> TaskRepo m (Maybe Task)
  ChangeTaskStatusOp :: Int -> PatchTaskCommand -> TaskRepo m (Maybe TaskStatusChanged)
  DeleteTaskOp :: Int -> TaskRepo m (Maybe ())

type instance DispatchOf TaskRepo = Dynamic

getTask :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
getTask tid = send (GetTaskOp tid)

getTaskAll :: (TaskRepo :> es) => Eff es [Task]
getTaskAll = send GetTasksOp

createTask :: (TaskRepo :> es) => CreateTaskCommand -> Text -> Text -> Eff es Task
createTask cmd createdAt updatedAt = send (CreateTaskOp cmd createdAt updatedAt)

replaceTask :: (TaskRepo :> es) => Int -> UpdateTaskCommand -> Eff es (Maybe Task)
replaceTask tid op = send (ReplaceTaskOp tid op)

changeTaskStatus :: (TaskRepo :> es) => Int -> PatchTaskCommand -> Eff es (Maybe TaskStatusChanged)
changeTaskStatus tid op = send (ChangeTaskStatusOp tid op)

deleteTask :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
deleteTask tid = send (DeleteTaskOp tid)
