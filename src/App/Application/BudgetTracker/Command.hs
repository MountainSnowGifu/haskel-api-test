{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.BudgetTracker.Command
  ( CreateRecordCommand (..),
  )
where

import App.Domain.BudgetTracker.Entity (RecordType)
import Data.Text (Text)
import GHC.Generics (Generic)

data CreateRecordCommand = CreateRecordCommand
  { cmdType      :: RecordType,
    cmdCategory  :: Text,
    cmdAmount    :: Int,
    cmdDate      :: Text,
    cmdMemo      :: Text,
    cmdCreatedAt :: Text,
    cmdUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)
