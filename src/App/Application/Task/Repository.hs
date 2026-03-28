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
import App.Application.Task.Command (ChangeTaskStatusCmd, CreateTaskCmd, ReplaceTaskCmd, TaskStatusChanged)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data TaskRepo :: Effect where
  GetTaskOp :: Int -> TaskRepo m (Maybe Task)
  GetTasksOp :: TaskRepo m [Task]
  CreateTaskOp :: CreateTaskCmd -> TaskRepo m Task
  ReplaceTaskOp :: Int -> ReplaceTaskCmd -> TaskRepo m (Maybe Task)
  ChangeTaskStatusOp :: Int -> ChangeTaskStatusCmd -> TaskRepo m (Maybe TaskStatusChanged)
  DeleteTaskOp :: Int -> TaskRepo m (Maybe ())

type instance DispatchOf TaskRepo = Dynamic

getTask :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
getTask tid = send (GetTaskOp tid)

getTaskAll :: (TaskRepo :> es) => Eff es [Task]
getTaskAll = send GetTasksOp

createTask :: (TaskRepo :> es) => CreateTaskCmd -> Eff es Task
createTask op = send (CreateTaskOp op)

replaceTask :: (TaskRepo :> es) => Int -> ReplaceTaskCmd -> Eff es (Maybe Task)
replaceTask tid op = send (ReplaceTaskOp tid op)

changeTaskStatus :: (TaskRepo :> es) => Int -> ChangeTaskStatusCmd -> Eff es (Maybe TaskStatusChanged)
changeTaskStatus tid op = send (ChangeTaskStatusOp tid op)

deleteTask :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
deleteTask tid = send (DeleteTaskOp tid)
