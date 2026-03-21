{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Task.UseCase
  ( getTaskResult,
    postTaskResult,
    getTaskAllResult,
    putTaskResult,
    patchTaskResult,
    deleteTaskResult,
  )
where

import App.Application.Task.Command (CreateTaskCommand, PatchTaskCommand, UpdateTaskCommand)
import App.Domain.Task.Entity (Task, TaskStatus)
import App.Domain.Task.Repository (TaskRepo, deleteTask, getTask, getTaskAll, patchTask, postTask, putTask)
import Data.Text (Text)
import Effectful

getTaskResult :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
getTaskResult = getTask

getTaskAllResult :: (TaskRepo :> es) => Eff es [Task]
getTaskAllResult = getTaskAll

postTaskResult :: (TaskRepo :> es) => CreateTaskCommand -> Eff es Task
postTaskResult = postTask

putTaskResult :: (TaskRepo :> es) => Int -> UpdateTaskCommand -> Eff es (Maybe Task)
putTaskResult = putTask

patchTaskResult :: (TaskRepo :> es) => Int -> PatchTaskCommand -> Eff es (Maybe (Int, TaskStatus, Text))
patchTaskResult = patchTask

deleteTaskResult :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
deleteTaskResult = deleteTask
