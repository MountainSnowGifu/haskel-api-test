{-# LANGUAGE DeriveGeneric #-}

module App.Presentation.HabitTracker.Response
  ( HabitResponse,
    toHabitResponse,
    HabitLogResponse,
    MonthlyReportResponse,
    toMonthlyReportResponse,
  )
where

import App.Domain.HabitTracker.Entity (Habit (Habit), HabitLog (..), HabitWithLogs (..), HabitWithStats (HabitWithStats))
import Data.Aeson (ToJSON)
import Data.Text (Text)
import Data.Time (Day, UTCTime)
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

data MonthlyReportResponse = MonthlyReportResponse
  { mrHabit :: HabitResponse,
    mrLogs :: [HabitLogResponse]
  }
  deriving (Show, Eq, Generic)

instance ToJSON MonthlyReportResponse

toMonthlyReportResponse :: HabitWithLogs -> MonthlyReportResponse
toMonthlyReportResponse (HabitWithLogs habit logs) =
  MonthlyReportResponse
    { mrHabit = habitToResponse habit,
      mrLogs = map toHabitLogResponse logs
    }

habitToResponse :: Habit -> HabitResponse
habitToResponse (Habit hId hTitle hDesc hColor hCat hCreated hUpdated) =
  HabitResponse
    { habitId = hId,
      habitTitle = hTitle,
      habitDescription = hDesc,
      habitColor = hColor,
      habitCategory = hCat,
      habitCurrentStreak = 0,
      habitBestStreak = 0,
      habitTotalCompletions = 0,
      habitTodayCompleted = False,
      habitCreatedAt = hCreated,
      habitUpdatedAt = hUpdated
    }

data HabitLogResponse = HabitLogResponse
  { hlHabitLogId :: Int,
    hlHabitLogDate :: Day,
    hlHabitLogStatus :: Text,
    hlHabitLogNote :: Text,
    hlHabitLogCreatedAt :: UTCTime
  }
  deriving (Show, Eq, Generic)

instance ToJSON HabitLogResponse

toHabitLogResponse :: HabitLog -> HabitLogResponse
toHabitLogResponse (HabitLog lId _ lDate lStatus lNote lCreated) =
  HabitLogResponse
    { hlHabitLogId = lId,
      hlHabitLogDate = lDate,
      hlHabitLogStatus = lStatus,
      hlHabitLogNote = lNote,
      hlHabitLogCreatedAt = lCreated
    }
