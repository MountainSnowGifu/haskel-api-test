{-# LANGUAGE DeriveGeneric #-}

module App.Presentation.BudgetTracker.Response
  ( RecordResponse (..),
    toRecordResponse,
  )
where

import App.Domain.BudgetTracker.Entity (Record (Record))
import Data.Aeson (ToJSON (..))
import GHC.Generics (Generic)

data RecordResponse = RecordResponse
  { recordId :: Int,
    recordUserId :: Int,
    recordType :: String,
    recordCategory :: String,
    recordAmount :: Int,
    recordDate :: String,
    recordMemo :: String
  }
  deriving (Show, Eq, Generic)

instance ToJSON RecordResponse

toRecordResponse :: Record -> RecordResponse
toRecordResponse (Record rid ruid rtype rcategory ramount rdate rmemo) =
  RecordResponse rid ruid rtype rcategory ramount rdate rmemo
