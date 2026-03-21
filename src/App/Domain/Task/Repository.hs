{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.Task.Repository
  ( TaskRepo (..),
    getTask,
    postTask,
    getTaskAll,
    putTask,
    patchTask,
    deleteTask,
  )
where

import App.Application.Task.Command (CreateTaskCommand, PatchTaskCommand, UpdateTaskCommand)
import App.Domain.Task.Entity (Task, TaskStatus)
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data TaskRepo :: Effect where
  GetTask :: Int -> TaskRepo m (Maybe Task)
  GetTaskAll :: TaskRepo m [Task]
  PostTask :: CreateTaskCommand -> TaskRepo m Task
  PutTask :: Int -> UpdateTaskCommand -> TaskRepo m (Maybe Task)
  PatchTask :: Int -> PatchTaskCommand -> TaskRepo m (Maybe (Int, TaskStatus, Text))
  DeleteTask :: Int -> TaskRepo m (Maybe ())

type instance DispatchOf TaskRepo = Dynamic

getTask :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
getTask tid = send (GetTask tid)

getTaskAll :: (TaskRepo :> es) => Eff es [Task]
getTaskAll = send GetTaskAll

postTask :: (TaskRepo :> es) => CreateTaskCommand -> Eff es Task
postTask cmd = send (PostTask cmd)

putTask :: (TaskRepo :> es) => Int -> UpdateTaskCommand -> Eff es (Maybe Task)
putTask tid task = send (PutTask tid task)

-- | PATCH 用クエリ: (id, status, updatedAt) を返す
patchTask :: (TaskRepo :> es) => Int -> PatchTaskCommand -> Eff es (Maybe (Int, TaskStatus, Text))
patchTask tid cmd = send (PatchTask tid cmd)

deleteTask :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
deleteTask tid = send (DeleteTask tid)
