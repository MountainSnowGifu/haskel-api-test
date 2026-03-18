{-# LANGUAGE DeriveGeneric #-}

module App.API.Marketing.Types
  ( ClientInfo (..),
    Email (..),
  )
where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

data ClientInfo = ClientInfo
  { clientName :: String,
    clientEmail :: String,
    clientAge :: Int,
    clientInterestedIn :: [String]
  }
  deriving (Generic)

instance FromJSON ClientInfo

instance ToJSON ClientInfo

data Email = Email
  { from :: String,
    to :: String,
    subject :: String,
    body :: String
  }
  deriving (Generic)

instance ToJSON Email
