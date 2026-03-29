{-# LANGUAGE DeriveGeneric #-}

module App.Presentation.HabitTracker.Response
  ( HabitResponse,
    toHabitResponse,
  )
where

import App.Domain.HabitTracker.Entity (Habit (Habit), HabitWithStats (HabitWithStats))
import Data.Aeson (ToJSON)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

data HabitResponse = HabitResponse
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

instance ToJSON HabitResponse

-- Habit と HabitWithStats はフィールド名が重複するため、
-- ポジション的パターンマッチでローカル変数に束縛して曖昧さを回避する。
toHabitResponse :: HabitWithStats -> HabitResponse
toHabitResponse
  ( HabitWithStats
      (Habit hId hTitle hDesc hColor hCat hCreated hUpdated)
      curStreak
      bestStreak
      totalComp
      todayDone
    ) =
    HabitResponse
      { habitId = hId,
        habitTitle = hTitle,
        habitDescription = hDesc,
        habitColor = hColor,
        habitCategory = hCat,
        habitCurrentStreak = curStreak,
        habitBestStreak = bestStreak,
        habitTotalCompletions = totalComp,
        habitTodayCompleted = todayDone,
        habitCreatedAt = hCreated,
        habitUpdatedAt = hUpdated
      }
