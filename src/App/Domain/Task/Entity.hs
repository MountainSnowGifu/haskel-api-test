{-# LANGUAGE DeriveGeneric #-}

module App.Domain.Task.Entity
  ( Task (..),
    TaskStatus (..),
    TaskPriority (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data TaskStatus = Todo | InProgress | Done
  deriving (Show, Eq, Generic)

data TaskPriority = Low | Medium | High
  deriving (Show, Eq, Generic)

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
