{-# LANGUAGE DeriveGeneric #-}

module App.Presentation.Chat.Request
  ( ConnectionInitRequest (..),
    MessageSendRequest (..),
    toConnectionInitCommand,
    toMessageSendCommand,
  )
where

import App.Application.Chat.Command (ConnectionInitCommand (..), MessageSendCommand (..))
import Data.Aeson (FromJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | WebSocket "connection.init" イベントの data 部
data ConnectionInitRequest = ConnectionInitRequest
  { userId :: Text,
    userName :: Text,
    roomId :: Text
  }
  deriving (Generic)

instance FromJSON ConnectionInitRequest

-- | WebSocket "message.send" イベントの data 部
newtype MessageSendRequest = MessageSendRequest
  { text :: Text
  }
  deriving (Generic)

instance FromJSON MessageSendRequest

toConnectionInitCommand :: ConnectionInitRequest -> ConnectionInitCommand
toConnectionInitCommand r = ConnectionInitCommand (userId r) (userName r) (roomId r)

toMessageSendCommand :: MessageSendRequest -> MessageSendCommand
toMessageSendCommand r = MessageSendCommand (text r)
