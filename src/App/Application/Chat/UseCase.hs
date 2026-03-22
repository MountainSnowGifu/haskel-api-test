{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Chat.UseCase
  ( ValidationError (..),
    validateMessageSend,
    initConnection,
    storeMessage,
    disconnectClient,
  )
where

import App.Application.Chat.Command (ConnectionInitCommand (..), MessageSendCommand (..))
import App.Domain.Chat.Entity (ChatMessage (..), ConnectedClient (..))
import App.Domain.Chat.Repository (ChatRepo, addClient, getClients, removeClient, saveMessage)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 (nextRandom)
import Effectful

-- ---------------------------------------------------------------------------
-- バリデーション（純粋：Effect 不要）
-- ---------------------------------------------------------------------------

data ValidationError = EmptyText | TextTooLong

validateMessageSend :: MessageSendCommand -> Either ValidationError MessageSendCommand
validateMessageSend cmd
  | T.null (cmdText cmd) = Left EmptyText
  | T.length (cmdText cmd) > 1000 = Left TextTooLong
  | otherwise = Right cmd

-- ---------------------------------------------------------------------------
-- ユースケース
-- ---------------------------------------------------------------------------

-- | 接続を初期化し RoomState に登録する。
-- WS への ack 送信・IORef への書き込みは呼び出し元（Handler）が行う。
initConnection ::
  (ChatRepo :> es, IOE :> es) =>
  ConnectionInitCommand ->
  Eff es ConnectedClient
initConnection cmd = do
  connId <- liftIO $ UUID.toText <$> nextRandom
  let client =
        ConnectedClient
          { clientUserId = cmdUserId cmd,
            clientUserName = cmdUserName cmd,
            clientRoomId = cmdRoomId cmd,
            clientConnId = connId
          }
  addClient client
  return client

-- | メッセージを保存し、ブロードキャスト対象クライアントを返す。
-- WS への実際の送信は呼び出し元（Handler）が行う。
storeMessage ::
  (ChatRepo :> es, IOE :> es) =>
  ConnectedClient ->
  Text ->
  Eff es (ChatMessage, [ConnectedClient])
storeMessage sender msgText = do
  msgId  <- liftIO $ UUID.toText <$> nextRandom
  sentAt <- liftIO $ T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" <$> getCurrentTime
  let msg =
        ChatMessage
          { chatMsgId       = msgId,
            chatMsgRoomId   = clientRoomId sender,
            chatMsgUserId   = clientUserId sender,
            chatMsgUserName = clientUserName sender,
            chatMsgText     = msgText,
            chatMsgSentAt   = sentAt
          }
  saveMessage msg
  clients <- getClients (clientRoomId sender)
  return (msg, clients)

-- | クライアントを RoomState から除去する。
-- 呼び出し前に Handler が IORef を読んで ConnectedClient を取り出す。
disconnectClient :: (ChatRepo :> es) => ConnectedClient -> Eff es ()
disconnectClient = removeClient
