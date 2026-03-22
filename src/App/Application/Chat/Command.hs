{-# LANGUAGE DeriveGeneric #-}

module App.Application.Chat.Command
  ( ConnectionInitCommand (..),
    MessageSendCommand (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data ConnectionInitCommand = ConnectionInitCommand
  { cmdUserId :: Text,
    cmdUserName :: Text,
    cmdRoomId :: Text
  }
  deriving (Show, Eq, Generic)

newtype MessageSendCommand = MessageSendCommand
  { cmdText :: Text
  }
  deriving (Show, Eq, Generic)
