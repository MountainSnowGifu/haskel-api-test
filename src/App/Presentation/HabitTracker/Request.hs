{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module App.Presentation.HabitTracker.Request
  ( PostHabitRequest,
    toCreateHabitCommand,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

data PostHabitRequest = PostHabitRequest
  { habitTitle :: Text,
    habitDescription :: Text,
    habitColor :: Text,
    habitCategory :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PostHabitRequest

instance ToJSON PostHabitRequest

toCreateHabitCommand :: PostHabitRequest -> CreateHabitCommand
toCreateHabitCommand PostHabitRequest {..} =
  CreateHabitCommand
    { cmdHabitTitle = habitTitle,
      cmdHabitDescription = habitDescription,
      cmdHabitColor = habitColor,
      cmdHabitCategory = habitCategory
    }

