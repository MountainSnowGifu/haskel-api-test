{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module App.Presentation.HabitTracker.Request
  ( PostHabitRequest,
    toCreateHabitCommand,
    PatchHabitRequest,
    toUpdateHabitCommand,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..), UpdateHabitCommand (..))
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

data PatchHabitRequest = PatchHabitRequest
  { habitTitle :: Text,
    habitDescription :: Text,
    habitColor :: Text,
    habitCategory :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PatchHabitRequest

instance ToJSON PatchHabitRequest

toUpdateHabitCommand :: Int -> PatchHabitRequest -> UpdateHabitCommand
toUpdateHabitCommand hid PatchHabitRequest {..} =
  UpdateHabitCommand
    { cmdUpdateHabitId = hid,
      cmdUpdateHabitTitle = habitTitle,
      cmdUpdateHabitDescription = habitDescription,
      cmdUpdateHabitColor = habitColor,
      cmdUpdateHabitCategory = habitCategory
    }