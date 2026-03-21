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

import App.Application.Task.UseCase (deleteTaskResult, getTaskAllResult, getTaskResult, patchTaskResult, postTaskResult, putTaskResult)
import App.Domain.Auth.Entity (User)
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Repository.TaskSQLServer (runTaskRepo)
import App.Presentation.Task.Request (PatchTaskRequest, PostTaskRequest, UpdateTaskRequest, toCreateTaskCommand, toPatchTaskCommand, toUpdateTaskCommand)
import App.Presentation.Task.Response (DeleteTaskResponse (..), PatchTaskResponse (..), TaskResponse, toTaskResponse)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant (Handler, err404, throwError)

-- | GET /task/:id ハンドラ
getTaskHandler :: MSSQLPool -> User -> Int -> Handler TaskResponse
getTaskHandler pool user tid = do
  result <- liftIO $ runEff (runTaskRepo pool user (getTaskResult tid))
  maybe (throwError err404) (return . toTaskResponse) result

-- | GET /task-all ハンドラ
getTaskAllHandler :: MSSQLPool -> User -> Handler [TaskResponse]
getTaskAllHandler pool user = do
  tasks <- liftIO $ runEff (runTaskRepo pool user getTaskAllResult)
  return (map toTaskResponse tasks)

-- | POST /task ハンドラ
postTaskHandler :: MSSQLPool -> User -> PostTaskRequest -> Handler TaskResponse
postTaskHandler pool user body = do
  task <- liftIO $ runEff (runTaskRepo pool user (postTaskResult (toCreateTaskCommand body)))
  return (toTaskResponse task)

-- | PUT /task/:id ハンドラ
putTaskHandler :: MSSQLPool -> User -> Int -> UpdateTaskRequest -> Handler TaskResponse
putTaskHandler pool user tid body = do
  result <- liftIO $ runEff (runTaskRepo pool user (putTaskResult tid (toUpdateTaskCommand body)))
  maybe (throwError err404) (return . toTaskResponse) result

-- | PATCH /task/:id ハンドラ
patchTaskHandler :: MSSQLPool -> User -> Int -> PatchTaskRequest -> Handler PatchTaskResponse
patchTaskHandler pool user tid body = do
  result <- liftIO $ runEff (runTaskRepo pool user (patchTaskResult tid (toPatchTaskCommand body)))
  case result of
    Nothing -> throwError err404
    Just (rowId, status, updatedAt) ->
      return $ PatchTaskResponse "Task updated successfully" rowId status updatedAt

-- | DELETE /task/:id ハンドラ
deleteTaskHandler :: MSSQLPool -> User -> Int -> Handler DeleteTaskResponse
deleteTaskHandler pool user tid = do
  result <- liftIO $ runEff (runTaskRepo pool user (deleteTaskResult tid))
  case result of
    Nothing -> throwError err404
    Just () -> return $ DeleteTaskResponse "Task deleted successfully"
