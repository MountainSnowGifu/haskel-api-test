{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module App.Presentation.HabitTracker.Response
  ( HabitResponse,
    toHabitResponse,
  )
where

import App.Domain.HabitTracker.Entity (Habit (..))
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

toHabitResponse :: Habit -> HabitResponse
toHabitResponse Habit {..} = HabitResponse {..}