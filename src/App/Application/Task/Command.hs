{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Task.Command
  ( UpdateTaskCommand (..),
    CreateTaskCommand (..),
    PatchTaskCommand (..),
    TaskStatusChanged (..),
  )
where

import App.Domain.Task.Entity (TaskPriority, TaskStatus)
import Data.Text (Text)
import GHC.Generics (Generic)

data CreateTaskCommand = CreateTaskCommand
  { cmdTitle :: Text,
    cmdDescription :: Text,
    cmdStatus :: TaskStatus,
    cmdPriority :: TaskPriority,
    cmdDueDate :: Text
  }
  deriving (Show, Eq, Generic)

data UpdateTaskCommand = UpdateTaskCommand
  { cmdTitle :: Text,
    cmdDescription :: Text,
    cmdStatus :: TaskStatus,
    cmdPriority :: TaskPriority,
    cmdDueDate :: Text
  }
  deriving (Show, Eq, Generic)

newtype PatchTaskCommand = PatchTaskCommand
  { cmdStatus :: TaskStatus
  }
  deriving (Show, Eq, Generic)

data TaskStatusChanged = TaskStatusChanged
  { taskStatusChangedId :: Int,
    taskStatusChangedStatus :: TaskStatus,
    taskStatusChangedAt :: Text
  }
  deriving (Show, Eq, Generic)
