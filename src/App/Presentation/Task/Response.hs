{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Task.Response
  ( TaskResponse (..),
    toTaskResponse,
    PatchTaskResponse (..),
    DeleteTaskResponse (..),
  )
where

import App.Domain.Task.Entity (Task (..), TaskPriority, TaskStatus)
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Text (Text)
import GHC.Generics (Generic)

data TaskResponse = TaskResponse
  { taskId :: Int,
    taskUserId :: Int,
    taskTitle :: Text,
    taskDescription :: Text,
    taskStatus :: TaskStatus,
    taskPriority :: TaskPriority,
    taskDueDate :: Text,
    taskCreatedAt :: Text,
    taskUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)

instance ToJSON TaskResponse

toTaskResponse :: Task -> TaskResponse
toTaskResponse (Task tid uid title desc status priority dueDate createdAt updatedAt) =
  TaskResponse tid uid title desc status priority dueDate createdAt updatedAt

-- | PATCH レスポンス
--   { "message": "...", "task": { "id": ..., "status": ..., "updatedAt": ... } }
data PatchTaskResponse = PatchTaskResponse
  { patchMessage :: Text,
    patchId :: Int,
    patchStatus :: TaskStatus,
    patchUpdatedAt :: Text
  }
  deriving (Show, Eq)

instance ToJSON PatchTaskResponse where
  toJSON r =
    object
      [ "message" .= patchMessage r,
        "task"
          .= object
            [ "id" .= patchId r,
              "status" .= patchStatus r,
              "updatedAt" .= patchUpdatedAt r
            ]
      ]

newtype DeleteTaskResponse = DeleteTaskResponse
  { deleteMessage :: Text
  }
  deriving (Show, Eq)

instance ToJSON DeleteTaskResponse where
  toJSON r = object ["message" .= deleteMessage r]
