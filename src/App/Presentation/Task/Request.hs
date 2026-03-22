{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

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
import App.Domain.Task.Entity (TaskPriority, TaskStatus)
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

data UpdateTaskRequest = UpdateTaskRequest
  { taskTitle :: Text,
    taskDescription :: Text,
    taskStatus :: TaskStatus,
    taskPriority :: TaskPriority,
    taskDueDate :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON UpdateTaskRequest

instance ToJSON UpdateTaskRequest

toUpdateTaskCommand :: UpdateTaskRequest -> UpdateTaskCommand
toUpdateTaskCommand (UpdateTaskRequest t d s p dd) =
  UpdateTaskCommand t d s p dd

data PostTaskRequest = PostTaskRequest
  { taskTitle :: Text,
    taskDescription :: Text,
    taskStatus :: TaskStatus,
    taskPriority :: TaskPriority,
    taskDueDate :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PostTaskRequest

instance ToJSON PostTaskRequest

toCreateTaskCommand :: PostTaskRequest -> CreateTaskCommand
toCreateTaskCommand (PostTaskRequest t d s p dd) =
  CreateTaskCommand t d s p dd T.empty T.empty

newtype PatchTaskRequest = PatchTaskRequest
  { status :: TaskStatus
  }
  deriving (Show, Eq, Generic)

instance FromJSON PatchTaskRequest

toPatchTaskCommand :: PatchTaskRequest -> PatchTaskCommand
toPatchTaskCommand (PatchTaskRequest s) = PatchTaskCommand s
