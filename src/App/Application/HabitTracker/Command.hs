{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.HabitTracker.Command
  ( CreateHabitCommand (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data CreateHabitCommand = CreateHabitCommand
  { cmdHabitTitle :: Text,
    cmdHabitDescription :: Text,
    cmdHabitColor :: Text,
    cmdHabitCategory :: Text
  }
  deriving (Show, Eq, Generic)
