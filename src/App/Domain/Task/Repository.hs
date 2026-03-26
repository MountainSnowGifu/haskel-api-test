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

import App.Domain.Task.Entity (NewTask, PatchedTask, Task, TaskPatch, UpdateTask)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data TaskRepo :: Effect where
  GetTask :: Int -> TaskRepo m (Maybe Task)
  GetTaskAll :: TaskRepo m [Task]
  PostTask :: NewTask -> TaskRepo m Task
  PutTask :: Int -> UpdateTask -> TaskRepo m (Maybe Task)
  PatchTask :: Int -> TaskPatch -> TaskRepo m (Maybe PatchedTask)
  DeleteTask :: Int -> TaskRepo m (Maybe ())

type instance DispatchOf TaskRepo = Dynamic

getTask :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
getTask tid = send (GetTask tid)

getTaskAll :: (TaskRepo :> es) => Eff es [Task]
getTaskAll = send GetTaskAll

postTask :: (TaskRepo :> es) => NewTask -> Eff es Task
postTask nt = send (PostTask nt)

putTask :: (TaskRepo :> es) => Int -> UpdateTask -> Eff es (Maybe Task)
putTask tid ut = send (PutTask tid ut)

patchTask :: (TaskRepo :> es) => Int -> TaskPatch -> Eff es (Maybe PatchedTask)
patchTask tid pt = send (PatchTask tid pt)

deleteTask :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
deleteTask tid = send (DeleteTask tid)
