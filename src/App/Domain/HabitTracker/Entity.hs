{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.HabitTracker.Entity
  ( Habit (..) )
where

import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

data Habit = Habit
  { habitId :: Int,
    habitTitle :: Text,
    habitDescription :: Text,
    habitColor :: Text,
    habitCategory :: Text,
    habitCurrentStreak :: Int,
    habitBestStreak :: Int,
    habitTotalCompletions :: Int,
    habitTodayCompleted :: Bool,
    habitCreatedAt :: UTCTime,
    habitUpdatedAt :: UTCTime
  }
  deriving (Show, Eq, Generic)
