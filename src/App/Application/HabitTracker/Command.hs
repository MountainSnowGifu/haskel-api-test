{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.HabitTracker.Command
  ( CreateHabitCommand (..),
    DeleteHabitCommand (..),
    UpdateHabitCommand (..),
    CreateHabitLogCommand (..),
    FetchHabitLogsCommand (..),
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

data UpdateHabitCommand = UpdateHabitCommand
  { cmdUpdateHabitId :: Int,
    cmdUpdateHabitTitle :: Text,
    cmdUpdateHabitDescription :: Text,
    cmdUpdateHabitColor :: Text,
    cmdUpdateHabitCategory :: Text
  }
  deriving (Show, Eq, Generic)

data CreateHabitLogCommand = CreateHabitLogCommand
  { cmdLogHabitId :: Int,
    cmdLogStatus :: Text
  }
  deriving (Show, Eq, Generic)

data FetchHabitLogsCommand = FetchHabitLogsCommand
  { cmdYear :: Int,
    cmdMonth :: Int
  }
  deriving (Show, Eq, Generic)