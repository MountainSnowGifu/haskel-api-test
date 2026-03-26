{-# LANGUAGE DeriveGeneric #-}

module App.Domain.HabitTracker.Operation
  ( CreateHabit (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data CreateHabit = CreateHabit
  { createHabitTitle :: Text,
    createHabitDescription :: Text,
    createHabitColor :: Text,
    createHabitCategory :: Text
  }
  deriving (Show, Eq, Generic)
