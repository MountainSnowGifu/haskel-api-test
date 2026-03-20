{-# LANGUAGE DeriveGeneric #-}

module App.Domain.Task.Entity
  ( Task (..),
    TaskStatus (..),
    TaskPriority (..),
  )
where

import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

data TaskStatus = Todo | InProgress | Done
  deriving (Show, Eq, Generic)

instance FromJSON TaskStatus

instance ToJSON TaskStatus

data TaskPriority = Low | Medium | High
  deriving (Show, Eq, Generic)

instance FromJSON TaskPriority

instance ToJSON TaskPriority

data Task = Task
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

instance FromJSON Task

instance ToJSON Task

-- {
--   "id": 101,
--   "userId": 1,
--   "title": "買い物に行く",
--   "description": "牛乳とパンを買う",
--   "status": "todo",
--   "priority": "medium",
--   "dueDate": "2026-03-20",
--   "createdAt": "2026-03-19T10:30:00Z",
--   "updatedAt": "2026-03-19T10:30:00Z"
-- }