{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.BudgetTracker.Response
  ( RecordResponse (..),
    toRecordResponse,
    SummaryResponse (..),
    toSummaryResponse,
    DeleteRecordResponse (..),
  )
where

import App.Domain.BudgetTracker.Entity (Record (Record), Summary (..))
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Text (Text)
import GHC.Generics (Generic)

data RecordResponse = RecordResponse
  { recordId :: Int,
    recordUserId :: Int,
    recordType :: Text,
    recordCategory :: Text,
    recordAmount :: Int,
    recordDate :: Text,
    recordMemo :: Text
  }
  deriving (Show, Eq, Generic)

instance ToJSON RecordResponse

toRecordResponse :: Record -> RecordResponse
toRecordResponse (Record rid ruid rtype rcategory ramount rdate rmemo) =
  RecordResponse rid ruid rtype rcategory ramount rdate rmemo

data SummaryResponse = SummaryResponse
  { month   :: Text,
    income  :: Int,
    expense :: Int,
    balance :: Int
  }
  deriving (Show, Eq, Generic)

instance ToJSON SummaryResponse

toSummaryResponse :: Summary -> SummaryResponse
toSummaryResponse s =
  SummaryResponse
    { month   = summaryMonth s,
      income  = summaryIncome s,
      expense = summaryExpense s,
      balance = summaryBalance s
    }

newtype DeleteRecordResponse = DeleteRecordResponse
  { deleteMessage :: Text
  }
  deriving (Show, Eq, Generic)

instance ToJSON DeleteRecordResponse where
  toJSON r = object ["message" .= deleteMessage r]
