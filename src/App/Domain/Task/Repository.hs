{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.Task.Repository
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
import App.Domain.Task.Operation (ChangeTaskStatus, CreateTask, ReplaceTask, TaskStatusChanged)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data TaskRepo :: Effect where
  GetTask :: Int -> TaskRepo m (Maybe Task)
  GetTaskAll :: TaskRepo m [Task]
  CreateTaskOp :: CreateTask -> TaskRepo m Task
  ReplaceTaskOp :: Int -> ReplaceTask -> TaskRepo m (Maybe Task)
  ChangeTaskStatusOp :: Int -> ChangeTaskStatus -> TaskRepo m (Maybe TaskStatusChanged)
  DeleteTask :: Int -> TaskRepo m (Maybe ())

type instance DispatchOf TaskRepo = Dynamic

getTask :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
getTask tid = send (GetTask tid)

getTaskAll :: (TaskRepo :> es) => Eff es [Task]
getTaskAll = send GetTaskAll

createTask :: (TaskRepo :> es) => CreateTask -> Eff es Task
createTask op = send (CreateTaskOp op)

replaceTask :: (TaskRepo :> es) => Int -> ReplaceTask -> Eff es (Maybe Task)
replaceTask tid op = send (ReplaceTaskOp tid op)

changeTaskStatus :: (TaskRepo :> es) => Int -> ChangeTaskStatus -> Eff es (Maybe TaskStatusChanged)
changeTaskStatus tid op = send (ChangeTaskStatusOp tid op)

deleteTask :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
deleteTask tid = send (DeleteTask tid)
