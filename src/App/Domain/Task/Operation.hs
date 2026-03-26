{-# LANGUAGE DeriveGeneric #-}

module App.Domain.Task.Operation
  ( CreateTask (..),
    ReplaceTask (..),
    ChangeTaskStatus (..),
    TaskStatusChanged (..),
  )
where

import App.Domain.Task.Entity (TaskPriority, TaskStatus)
import Data.Text (Text)
import GHC.Generics (Generic)

data CreateTask = CreateTask
  { createTaskTitle :: Text,
    createTaskDescription :: Text,
    createTaskStatus :: TaskStatus,
    createTaskPriority :: TaskPriority,
    createTaskDueDate :: Text,
    createTaskCreatedAt :: Text,
    createTaskUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)

data ReplaceTask = ReplaceTask
  { replaceTaskTitle :: Text,
    replaceTaskDescription :: Text,
    replaceTaskStatus :: TaskStatus,
    replaceTaskPriority :: TaskPriority,
    replaceTaskDueDate :: Text
  }
  deriving (Show, Eq, Generic)

newtype ChangeTaskStatus = ChangeTaskStatus
  { changeTaskStatus :: TaskStatus
  }
  deriving (Show, Eq, Generic)

data TaskStatusChanged = TaskStatusChanged
  { taskStatusChangedId :: Int,
    taskStatusChangedStatus :: TaskStatus,
    taskStatusChangedAt :: Text
  }
  deriving (Show, Eq, Generic)
