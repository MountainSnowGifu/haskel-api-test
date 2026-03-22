{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Domain.Chat.Entity
  ( ConnectedClient (..),
    RoomState,
    newRoomState,
    ChatMessage (..),
    MessageStore,
    newMessageStore,
    ErrorCode (..),
    errorCodeText,
  )
where

import Control.Concurrent.STM (TVar, newTVarIO)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Network.WebSockets qualified as WS

-- | ルームに接続中のクライアント情報
data ConnectedClient = ConnectedClient
  { clientConn :: WS.Connection,
    clientUserId :: Text,
    clientUserName :: Text,
    clientRoomId :: Text,
    clientConnId :: Text
  }

-- | roomId → 接続クライアント一覧
type RoomState = TVar (Map Text [ConnectedClient])

newRoomState :: IO RoomState
newRoomState = newTVarIO Map.empty

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

-- | roomId → メッセージ履歴（送信順）
type MessageStore = TVar (Map Text [ChatMessage])

newMessageStore :: IO MessageStore
newMessageStore = newTVarIO Map.empty

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
