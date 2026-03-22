{-# LANGUAGE DeriveGeneric #-}

module App.Domain.BudgetTracker.Entity
  ( Record (..),
  )
where

import GHC.Generics (Generic)

data Record = Record
  { recordId :: Int,
    recordUserId :: Int,
    recordType :: String,
    recordCategory :: String,
    recordAmount :: Int,
    recordDate :: String,
    recordMemo :: String
  }
  deriving (Show, Eq, Generic)