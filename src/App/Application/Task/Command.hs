{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Task.Command
  ( UpdateTaskCommand (..),
    CreateTaskCommand (..),
    PatchTaskCommand (..),
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
