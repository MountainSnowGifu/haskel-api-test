{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Task.Handler
  ( getTaskHandler,
    postTaskHandler,
    getTaskAllHandler,
    putTaskHandler,
    patchTaskHandler,
    deleteTaskHandler,
  )
where

import App.Application.Task.UseCase (TaskValidationError (..), createTask, fetchAllTasks, fetchTask, removeTask, replaceTask, updateTaskStatus)
import App.Domain.Auth.Entity (User)
import App.Domain.Task.Entity (PatchedTask (..))
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Repository.TaskSQLServer (runTaskRepo)
import App.Presentation.Task.Request (PatchTaskRequest, PostTaskRequest, UpdateTaskRequest, toCreateTaskCommand, toPatchTaskCommand, toUpdateTaskCommand)
import App.Presentation.Task.Response (DeleteTaskResponse (..), PatchTaskResponse (..), TaskResponse, toTaskResponse)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant (Handler, err400, err404, throwError)

-- | GET /task/:id ハンドラ
getTaskHandler :: MSSQLPool -> User -> Int -> Handler TaskResponse
getTaskHandler pool user tid = do
  result <- liftIO $ runEff (runTaskRepo pool user (fetchTask tid))
  maybe (throwError err404) (return . toTaskResponse) result

-- | GET /task-all ハンドラ
getTaskAllHandler :: MSSQLPool -> User -> Handler [TaskResponse]
getTaskAllHandler pool user = do
  tasks <- liftIO $ runEff (runTaskRepo pool user fetchAllTasks)
  return (map toTaskResponse tasks)

-- | POST /task ハンドラ
postTaskHandler :: MSSQLPool -> User -> PostTaskRequest -> Handler TaskResponse
postTaskHandler pool user body = do
  result <- liftIO $ runEff (runTaskRepo pool user (createTask (toCreateTaskCommand body)))
  case result of
    Left TitleEmpty -> throwError err400
    Left TitleTooLong -> throwError err400
    Right task -> return (toTaskResponse task)

-- | PUT /task/:id ハンドラ
putTaskHandler :: MSSQLPool -> User -> Int -> UpdateTaskRequest -> Handler TaskResponse
putTaskHandler pool user tid body = do
  result <- liftIO $ runEff (runTaskRepo pool user (replaceTask tid (toUpdateTaskCommand body)))
  maybe (throwError err404) (return . toTaskResponse) result

-- | PATCH /task/:id ハンドラ
patchTaskHandler :: MSSQLPool -> User -> Int -> PatchTaskRequest -> Handler PatchTaskResponse
patchTaskHandler pool user tid body = do
  result <- liftIO $ runEff (runTaskRepo pool user (updateTaskStatus tid (toPatchTaskCommand body)))
  case result of
    Nothing -> throwError err404
    Just pt ->
      return $ PatchTaskResponse "Task updated successfully" (patchedId pt) (patchedStatus pt) (patchedAt pt)

-- | DELETE /task/:id ハンドラ
deleteTaskHandler :: MSSQLPool -> User -> Int -> Handler DeleteTaskResponse
deleteTaskHandler pool user tid = do
  result <- liftIO $ runEff (runTaskRepo pool user (removeTask tid))
  case result of
    Nothing -> throwError err404
    Just () -> return $ DeleteTaskResponse "Task deleted successfully"
