{-# LANGUAGE DeriveGeneric #-}

module App.Domain.BudgetTracker.Entity
  ( Record (..),
    RecordType (..),
    Summary (..),
    summarize,
    NewRecord (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data RecordType = Income | Expense
  deriving (Show, Eq, Generic)

data Record = Record
  { recordId :: Int,
    recordUserId :: Int,
    recordType :: RecordType,
    recordCategory :: Text,
    recordAmount :: Int,
    recordDate :: Text,
    recordMemo :: Text
  }
  deriving (Show, Eq, Generic)

data Summary = Summary
  { summaryMonth :: Text,
    summaryIncome :: Int,
    summaryExpense :: Int,
    summaryBalance :: Int
  }
  deriving (Show, Eq, Generic)

data NewRecord = NewRecord
  { newRecordType :: RecordType,
    newRecordCategory :: Text,
    newRecordAmount :: Int,
    newRecordDate :: Text,
    newRecordMemo :: Text
  }
  deriving (Show, Eq, Generic)

summarize :: Text -> [Record] -> Summary
summarize month records =
  let income = sum [recordAmount r | r <- records, recordType r == Income]
      expense = sum [recordAmount r | r <- records, recordType r == Expense]
   in Summary
        { summaryMonth = month,
          summaryIncome = income,
          summaryExpense = expense,
          summaryBalance = income - expense
        }
