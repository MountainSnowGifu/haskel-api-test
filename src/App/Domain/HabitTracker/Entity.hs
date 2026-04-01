{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.HabitTracker.Entity (Habit (..), HabitLog (..), HabitWithStats (..), HabitWithLogs (..)) where

import Data.Text (Text)
import Data.Time (Day, UTCTime)
import GHC.Generics (Generic)

-- 永続化された状態のみ保持する。派生値（ストリーク等）は含まない。
data Habit = Habit
  { habitId :: Int,
    habitTitle :: Text,
    habitDescription :: Text,
    habitColor :: Text,
    habitCategory :: Text,
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

-- HabitLog から計算した統計情報。Application 層で組み立てる。
data HabitWithStats = HabitWithStats
  { hwsHabit :: Habit,
    hwsCurrentStreak :: Int,
    hwsBestStreak :: Int,
    hwsTotalCompletions :: Int,
    hwsTodayCompleted :: Bool
  }
  deriving (Show, Eq, Generic)

data HabitWithLogs = HabitWithLogs
  { hwlHabit :: Habit,
    hwlLogs :: [HabitLog]
  }
  deriving (Show, Eq, Generic)
