{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.BudgetTracker.Command
  ( CreateRecordCommand (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data CreateRecordCommand = CreateRecordCommand
  { cmdType      :: Text,
    cmdCategory  :: Text,
    cmdAmount    :: Int,
    cmdDate      :: Text,
    cmdMemo      :: Text,
    cmdCreatedAt :: Text,
    cmdUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)
