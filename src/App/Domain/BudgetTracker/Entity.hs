{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Domain.BudgetTracker.Entity
  ( Record (..),
    Summary (..),
    summarize,
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data Summary = Summary
  { summaryMonth :: Text,
    summaryIncome :: Int,
    summaryExpense :: Int,
    summaryBalance :: Int
  }
  deriving (Show, Eq, Generic)

summarize :: Text -> [Record] -> Summary
summarize month records =
  let income = sum [recordAmount r | r <- records, recordType r == "income"]
      expense = sum [recordAmount r | r <- records, recordType r == "expense"]
   in Summary
        { summaryMonth = month,
          summaryIncome = income,
          summaryExpense = expense,
          summaryBalance = income - expense
        }

data Record = Record
  { recordId :: Int,
    recordUserId :: Int,
    recordType :: Text,
    recordCategory :: Text,
    recordAmount :: Int,
    recordDate :: Text,
    recordMemo :: Text
  }
  deriving (Show, Eq, Generic)