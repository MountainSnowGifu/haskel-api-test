{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module App.Presentation.Task.Request
  ( UpdateTaskRequest (..),
    toUpdateTaskCommand,
    PostTaskRequest (..),
    toCreateTaskCommand,
    PatchTaskRequest (..),
    toPatchTaskCommand,
  )
where

import App.Application.Task.Command (CreateTaskCommand (..), PatchTaskCommand (..), UpdateTaskCommand (..))
import App.Domain.Task.Entity (TaskPriority (..), TaskStatus (..))
import Data.Aeson (FromJSON)
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

instance FromJSON TaskStatus

instance FromJSON TaskPriority

data UpdateTaskRequest = UpdateTaskRequest
  { taskTitle :: Text,
    taskDescription :: Text,
    taskStatus :: TaskStatus,
    taskPriority :: TaskPriority,
    taskDueDate :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON UpdateTaskRequest

toUpdateTaskCommand :: UpdateTaskRequest -> UpdateTaskCommand
toUpdateTaskCommand UpdateTaskRequest {taskTitle = t, taskDescription = d, taskStatus = s, taskPriority = p, taskDueDate = dd} =
  UpdateTaskCommand
    { cmdTitle = t,
      cmdDescription = d,
      cmdStatus = s,
      cmdPriority = p,
      cmdDueDate = dd
    }

data PostTaskRequest = PostTaskRequest
  { taskTitle :: Text,
    taskDescription :: Text,
    taskStatus :: TaskStatus,
    taskPriority :: TaskPriority,
    taskDueDate :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PostTaskRequest

toCreateTaskCommand :: PostTaskRequest -> CreateTaskCommand
toCreateTaskCommand PostTaskRequest {taskTitle = t, taskDescription = d, taskStatus = s, taskPriority = p, taskDueDate = dd} =
  CreateTaskCommand
    { cmdTitle = t,
      cmdDescription = d,
      cmdStatus = s,
      cmdPriority = p,
      cmdDueDate = dd,
      cmdCreatedAt = T.empty,
      cmdUpdatedAt = T.empty
    }

newtype PatchTaskRequest = PatchTaskRequest
  { status :: TaskStatus
  }
  deriving (Show, Eq, Generic)

instance FromJSON PatchTaskRequest

toPatchTaskCommand :: PatchTaskRequest -> PatchTaskCommand
toPatchTaskCommand (PatchTaskRequest s) = PatchTaskCommand s
