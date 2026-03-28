{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.HabitTracker.Command
  ( CreateHabitCommand (..),
    DeleteHabitCommand (..),
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

newtype DeleteHabitCommand = DeleteHabitCommand {cmdDeleteHabitId :: Int}
  deriving (Show, Eq, Generic)
