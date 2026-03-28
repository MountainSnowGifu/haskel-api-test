{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Task.Command
  ( UpdateTaskCommand (..),
    CreateTaskCommand (..),
    PatchTaskCommand (..),
    CreateTaskCmd (..),
    ReplaceTaskCmd (..),
    ChangeTaskStatusCmd (..),
    TaskStatusChanged (..),
  )
where

import App.Domain.Task.Entity (TaskPriority, TaskStatus)
import Data.Text (Text)
import GHC.Generics (Generic)

data UpdateTaskCommand = UpdateTaskCommand
  { cmdTitle :: Text,
    cmdDescription :: Text,
    cmdStatus :: TaskStatus,
    cmdPriority :: TaskPriority,
    cmdDueDate :: Text
  }
  deriving (Show, Eq, Generic)

data CreateTaskCommand = CreateTaskCommand
  { cmdTitle :: Text,
    cmdDescription :: Text,
    cmdStatus :: TaskStatus,
    cmdPriority :: TaskPriority,
    cmdDueDate :: Text,
    cmdCreatedAt :: Text,
    cmdUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)

newtype PatchTaskCommand = PatchTaskCommand
  { cmdStatus :: TaskStatus
  }
  deriving (Show, Eq, Generic)

data CreateTaskCmd = CreateTaskCmd
  { createTaskTitle :: Text,
    createTaskDescription :: Text,
    createTaskStatus :: TaskStatus,
    createTaskPriority :: TaskPriority,
    createTaskDueDate :: Text,
    createTaskCreatedAt :: Text,
    createTaskUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)

data ReplaceTaskCmd = ReplaceTaskCmd
  { replaceTaskTitle :: Text,
    replaceTaskDescription :: Text,
    replaceTaskStatus :: TaskStatus,
    replaceTaskPriority :: TaskPriority,
    replaceTaskDueDate :: Text
  }
  deriving (Show, Eq, Generic)

newtype ChangeTaskStatusCmd = ChangeTaskStatusCmd
  { changeTaskStatus :: TaskStatus
  }
  deriving (Show, Eq, Generic)

data TaskStatusChanged = TaskStatusChanged
  { taskStatusChangedId :: Int,
    taskStatusChangedStatus :: TaskStatus,
    taskStatusChangedAt :: Text
  }
  deriving (Show, Eq, Generic)
