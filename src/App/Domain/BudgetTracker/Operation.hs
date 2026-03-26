{-# LANGUAGE DeriveGeneric #-}

module App.Domain.BudgetTracker.Operation
  ( CreateRecord (..),
  )
where

import App.Domain.BudgetTracker.Entity (RecordType)
import Data.Text (Text)
import GHC.Generics (Generic)

data CreateRecord = CreateRecord
  { createRecordType :: RecordType,
    createRecordCategory :: Text,
    createRecordAmount :: Int,
    createRecordDate :: Text,
    createRecordMemo :: Text
  }
  deriving (Show, Eq, Generic)
