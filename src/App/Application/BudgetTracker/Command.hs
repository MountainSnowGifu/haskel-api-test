{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.BudgetTracker.Command
  ( CreateRecordCommand (..),
    CreateRecordCmd (..),
  )
where

import App.Domain.BudgetTracker.Entity (RecordType)
import Data.Text (Text)
import GHC.Generics (Generic)

data CreateRecordCommand = CreateRecordCommand
  { cmdRecordType :: RecordType,
    cmdRecordCategory :: Text,
    cmdRecordAmount :: Int,
    cmdRecordDate :: Text,
    cmdRecordMemo :: Text,
    cmdRecordCreatedAt :: Text,
    cmdRecordUpdatedAt :: Text
  }
  deriving (Show, Eq, Generic)

data CreateRecordCmd = CreateRecordCmd
  { createRecordType :: RecordType,
    createRecordCategory :: Text,
    createRecordAmount :: Int,
    createRecordDate :: Text,
    createRecordMemo :: Text
  }
  deriving (Show, Eq, Generic)
