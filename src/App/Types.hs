{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE InstanceSigs #-}

module App.Types
  ( Position (..),
    HelloMessage (..),
    ClientInfo (..),
    Email (..),
    NameWrapper (..),
  )
where

import Data.Aeson (FromJSON, ToJSON, parseJSON)
import GHC.Generics (Generic)

data Position = Position
  { xCoord :: Int,
    yCoord :: Int
  }
  deriving (Generic)

instance ToJSON Position

newtype HelloMessage = HelloMessage {msg :: String}
  deriving (Generic)

instance ToJSON HelloMessage

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

instance FromJSON NameWrapper where
  parseJSON v = NameWrapper <$> parseJSON v

newtype NameWrapper = NameWrapper String
