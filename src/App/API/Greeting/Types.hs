{-# LANGUAGE DeriveGeneric #-}

module App.API.Greeting.Types
  ( Position (..),
    HelloMessage (..),
  )
where

import Data.Aeson (ToJSON)
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
