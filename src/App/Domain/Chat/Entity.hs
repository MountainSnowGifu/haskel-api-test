{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Domain.Chat.Entity
  ( ConnectedClient (..),
    ChatMessage (..),
    ErrorCode (..),
    errorCodeText,
  )
where

import Data.Aeson (ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | ルームに接続中のクライアント情報
data ConnectedClient = ConnectedClient
  { clientUserId :: Text,
    clientUserName :: Text,
    clientRoomId :: Text,
    clientConnId :: Text
  }
  deriving (Generic)

-- ---------------------------------------------------------------------------
-- メッセージ永続化
-- ---------------------------------------------------------------------------

-- | 送受信された1件のチャットメッセージ
data ChatMessage = ChatMessage
  { chatMsgId :: Text,
    chatMsgRoomId :: Text,
    chatMsgUserId :: Text,
    chatMsgUserName :: Text,
    chatMsgText :: Text,
    chatMsgSentAt :: Text
  }
  deriving (Generic)

instance ToJSON ChatMessage

-- ---------------------------------------------------------------------------
-- エラーコード
-- ---------------------------------------------------------------------------

data ErrorCode
  = AuthFailed
  | RoomNotFound
  | MessageInvalid
  | InternalError

errorCodeText :: ErrorCode -> Text
errorCodeText AuthFailed = "AUTH_FAILED"
errorCodeText RoomNotFound = "ROOM_NOT_FOUND"
errorCodeText MessageInvalid = "MESSAGE_INVALID"
errorCodeText InternalError = "INTERNAL_ERROR"
