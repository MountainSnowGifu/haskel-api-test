{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.Task.Handler
  ( TaskRunner,
    getTaskHandler,
    postTaskHandler,
    getTaskAllHandler,
    putTaskHandler,
    patchTaskHandler,
    deleteTaskHandler,
  )
where

import App.Application.Task.UseCase (TaskValidationError (..), createTask, fetchAllTasks, fetchTask, removeTask, replaceTask, updateTaskStatus)
import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.Task.Command (TaskStatusChanged (..))
import App.Application.Task.Repository (TaskRepo)
import App.Presentation.Task.Request (PatchTaskRequest, PostTaskRequest, UpdateTaskRequest, toCreateTaskCommand, toPatchTaskCommand, toUpdateTaskCommand)
import App.Presentation.Task.Response (DeleteTaskResponse (..), PatchTaskResponse (..), TaskResponse, toTaskResponse)
import Control.Monad.IO.Class (liftIO)
import Effectful (Eff, IOE)
import Servant (Handler, err400, err404, throwError)

type TaskRunner = forall a. Eff '[TaskRepo, IOE] a -> IO a

-- | GET /task/:id ハンドラ
getTaskHandler :: (AuthPrincipal -> TaskRunner) -> AuthPrincipal -> Int -> Handler TaskResponse
getTaskHandler mkRun user tid = do
  result <- liftIO $ mkRun user (fetchTask tid)
  maybe (throwError err404) (return . toTaskResponse) result

-- | GET /task-all ハンドラ
getTaskAllHandler :: (AuthPrincipal -> TaskRunner) -> AuthPrincipal -> Handler [TaskResponse]
getTaskAllHandler mkRun user = do
  tasks <- liftIO $ mkRun user fetchAllTasks
  return (map toTaskResponse tasks)

-- | POST /task ハンドラ
postTaskHandler :: (AuthPrincipal -> TaskRunner) -> AuthPrincipal -> PostTaskRequest -> Handler TaskResponse
postTaskHandler mkRun user body = do
  result <- liftIO $ mkRun user (createTask (toCreateTaskCommand body))
  case result of
    Left TitleEmpty   -> throwError err400
    Left TitleTooLong -> throwError err400
    Right task        -> return (toTaskResponse task)

-- | PUT /task/:id ハンドラ
putTaskHandler :: (AuthPrincipal -> TaskRunner) -> AuthPrincipal -> Int -> UpdateTaskRequest -> Handler TaskResponse
putTaskHandler mkRun user tid body = do
  result <- liftIO $ mkRun user (replaceTask tid (toUpdateTaskCommand body))
  maybe (throwError err404) (return . toTaskResponse) result

-- | PATCH /task/:id ハンドラ
patchTaskHandler :: (AuthPrincipal -> TaskRunner) -> AuthPrincipal -> Int -> PatchTaskRequest -> Handler PatchTaskResponse
patchTaskHandler mkRun user tid body = do
  result <- liftIO $ mkRun user (updateTaskStatus tid (toPatchTaskCommand body))
  case result of
    Nothing -> throwError err404
    Just pt ->
      return $
        PatchTaskResponse
          "Task updated successfully"
          (taskStatusChangedId pt)
          (taskStatusChangedStatus pt)
          (taskStatusChangedAt pt)

-- | DELETE /task/:id ハンドラ
deleteTaskHandler :: (AuthPrincipal -> TaskRunner) -> AuthPrincipal -> Int -> Handler DeleteTaskResponse
deleteTaskHandler mkRun user tid = do
  result <- liftIO $ mkRun user (removeTask tid)
  case result of
    Nothing -> throwError err404
    Just () -> return $ DeleteTaskResponse "Task deleted successfully"
