{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.HabitTracker.Entity (Habit (..), HabitLog (..)) where

import Data.Text (Text)
import Data.Time (Day, UTCTime)
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

data HabitLog = HabitLog
  { habitLogId :: Int,
    habitLogHabitId :: Int,
    habitLogDate :: Day,
    habitLogStatus :: Text,
    habitLogNote :: Text,
    habitLogCreatedAt :: UTCTime
  }
  deriving (Show, Eq, Generic)