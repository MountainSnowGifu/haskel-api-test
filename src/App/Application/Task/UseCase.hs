{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Task.UseCase
  ( TaskValidationError (..),
    validateCreate,
    createTask,
    fetchTask,
    fetchAllTasks,
    replaceTask,
    updateTaskStatus,
    removeTask,
  )
where

import App.Application.Task.Command (ChangeTaskStatusCmd (..), CreateTaskCmd (..), CreateTaskCommand (..), PatchTaskCommand (..), ReplaceTaskCmd (..), TaskStatusChanged, UpdateTaskCommand (..))
import App.Domain.Task.Entity (Task)
import App.Domain.Task.Repository (TaskRepo, deleteTask, getTask, getTaskAll)
import App.Domain.Task.Repository qualified as TaskRepo
import Data.Text qualified as T
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime)
import Effectful

-- ---------------------------------------------------------------------------
-- バリデーション（純粋：Effect 不要）
-- ---------------------------------------------------------------------------

data TaskValidationError = TitleEmpty | TitleTooLong

validateCreate :: CreateTaskCommand -> Either TaskValidationError CreateTaskCommand
validateCreate cmd@(CreateTaskCommand t _ _ _ _ _ _)
  | T.null t = Left TitleEmpty
  | T.length t > 100 = Left TitleTooLong
  | otherwise = Right cmd

-- ---------------------------------------------------------------------------
-- ユースケース
-- ---------------------------------------------------------------------------

-- | タスクを新規作成する。タイムスタンプは UseCase が生成する。
createTask ::
  (TaskRepo :> es, IOE :> es) =>
  CreateTaskCommand ->
  Eff es (Either TaskValidationError Task)
createTask cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right (CreateTaskCommand t d s p dd _ _) -> do
    now <- liftIO $ T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" <$> getCurrentTime
    Right <$> TaskRepo.createTask (CreateTaskCmd t d s p dd now now)

fetchTask :: (TaskRepo :> es) => Int -> Eff es (Maybe Task)
fetchTask = getTask

fetchAllTasks :: (TaskRepo :> es) => Eff es [Task]
fetchAllTasks = getTaskAll

replaceTask :: (TaskRepo :> es) => Int -> UpdateTaskCommand -> Eff es (Maybe Task)
replaceTask tid (UpdateTaskCommand t d s p dd) =
  TaskRepo.replaceTask tid (ReplaceTaskCmd t d s p dd)

updateTaskStatus :: (TaskRepo :> es) => Int -> PatchTaskCommand -> Eff es (Maybe TaskStatusChanged)
updateTaskStatus tid (PatchTaskCommand s) =
  TaskRepo.changeTaskStatus tid (ChangeTaskStatusCmd s)

removeTask :: (TaskRepo :> es) => Int -> Eff es (Maybe ())
removeTask = deleteTask
