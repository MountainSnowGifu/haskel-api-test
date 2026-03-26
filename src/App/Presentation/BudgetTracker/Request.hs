{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.BudgetTracker.Request
  ( PostRecordRequest (..),
    toCreateRecordCommand,
  )
where

import App.Application.BudgetTracker.Command (CreateRecordCommand (..))
import App.Domain.BudgetTracker.Entity (RecordType (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

data PostRecordRequest = PostRecordRequest
  { recordType :: Text,
    recordCategory :: Text,
    recordAmount :: Int,
    recordDate :: Text,
    recordMemo :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PostRecordRequest

instance ToJSON PostRecordRequest

parseRecordType :: Text -> RecordType
parseRecordType "income" = Income
parseRecordType _ = Expense

toCreateRecordCommand :: PostRecordRequest -> CreateRecordCommand
toCreateRecordCommand req =
  CreateRecordCommand
    { cmdRecordType = parseRecordType (recordType req),
      cmdRecordCategory = recordCategory req,
      cmdRecordAmount = recordAmount req,
      cmdRecordDate = recordDate req,
      cmdRecordMemo = recordMemo req,
      cmdRecordCreatedAt = T.empty,
      cmdRecordUpdatedAt = T.empty
    }
