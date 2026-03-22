{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Application.Chat.UseCase
  ( ConnectionInitData (..),
    MessageSendData (..),
    ValidationError (..),
    validateMessageSend,
    sendError,
    handleEvent,
    handleConnectionInit,
    handleMessageSend,
    broadcastMessage,
    removeClient,
  )
where

import App.Domain.Chat.Entity (ChatMessage (..), ConnectedClient (..), ErrorCode (..), MessageStore, RoomState, errorCodeText)
import Control.Concurrent.STM (atomically, modifyTVar, readTVar)
import Control.Monad (forM_)
import Data.Aeson (FromJSON, Result (..), Value (..), encode, fromJSON, object, (.=))
import Data.Aeson.KeyMap qualified as KM
import Data.IORef (IORef, readIORef, writeIORef)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 (nextRandom)
import GHC.Generics (Generic)
import Data.Map.Strict qualified as Map
import Network.WebSockets qualified as WS

-- ---------------------------------------------------------------------------
-- データ型
-- ---------------------------------------------------------------------------

-- | connection.init のデータ部
data ConnectionInitData = ConnectionInitData
  { userId :: Text,
    userName :: Text,
    roomId :: Text
  }
  deriving (Generic)

instance FromJSON ConnectionInitData

-- | message.send のデータ部
newtype MessageSendData = MessageSendData
  { text :: Text
  }
  deriving (Generic)

instance FromJSON MessageSendData

-- ---------------------------------------------------------------------------
-- バリデーション
-- ---------------------------------------------------------------------------

data ValidationError = EmptyText | TextTooLong

validateMessageSend :: MessageSendData -> Either ValidationError MessageSendData
validateMessageSend d
  | T.null (text d) = Left EmptyText
  | T.length (text d) > 1000 = Left TextTooLong
  | otherwise = Right d

-- ---------------------------------------------------------------------------
-- エラー送信
-- ---------------------------------------------------------------------------

sendError :: WS.Connection -> ErrorCode -> Text -> IO ()
sendError conn code msg =
  WS.sendTextData conn $
    encode $
      object
        [ "event" .= ("error" :: Text),
          "data"
            .= object
              [ "code" .= errorCodeText code,
                "message" .= msg
              ]
        ]

-- ---------------------------------------------------------------------------
-- イベントハンドラ
-- ---------------------------------------------------------------------------

handleEvent :: RoomState -> MessageStore -> WS.Connection -> IORef (Maybe ConnectedClient) -> KM.KeyMap Value -> IO ()
handleEvent rooms store conn clientRef km = case KM.lookup "event" km of
  Just (String "ping") ->
    WS.sendTextData conn $
      encode $
        object
          [ "event" .= ("pong" :: Text),
            "data" .= object []
          ]
  Just (String "connection.init") ->
    case KM.lookup "data" km of
      Just dataVal -> case fromJSON dataVal of
        Success initData -> handleConnectionInit rooms conn clientRef initData
        Error _ -> return ()
      Nothing -> return ()
  Just (String "message.send") ->
    case KM.lookup "data" km of
      Just dataVal -> case fromJSON dataVal of
        Success msgData -> handleMessageSend rooms store conn clientRef msgData
        Error _ -> return ()
      Nothing -> return ()
  _ -> return ()

handleConnectionInit :: RoomState -> WS.Connection -> IORef (Maybe ConnectedClient) -> ConnectionInitData -> IO ()
handleConnectionInit rooms conn clientRef initData = do
  connId <- UUID.toText <$> nextRandom
  let client =
        ConnectedClient
          { clientConn = conn,
            clientUserId = userId initData,
            clientUserName = userName initData,
            clientRoomId = roomId initData,
            clientConnId = connId
          }
  atomically $ modifyTVar rooms $ Map.insertWith (++) (roomId initData) [client]
  writeIORef clientRef (Just client)
  WS.sendTextData conn $
    encode $
      object
        [ "event" .= ("connection.ack" :: Text),
          "data"
            .= object
              [ "userId" .= userId initData,
                "userName" .= userName initData,
                "roomId" .= roomId initData,
                "connectionId" .= connId
              ]
        ]

handleMessageSend :: RoomState -> MessageStore -> WS.Connection -> IORef (Maybe ConnectedClient) -> MessageSendData -> IO ()
handleMessageSend rooms store conn clientRef msgData =
  case validateMessageSend msgData of
    Left EmptyText -> sendError conn MessageInvalid "text は必須です"
    Left TextTooLong -> sendError conn MessageInvalid "text は1000文字以内です"
    Right d -> do
      mClient <- readIORef clientRef
      case mClient of
        Nothing -> return ()
        Just sender -> broadcastMessage rooms store sender (text d)

broadcastMessage :: RoomState -> MessageStore -> ConnectedClient -> Text -> IO ()
broadcastMessage rooms store sender msgText = do
  msgId <- UUID.toText <$> nextRandom
  sentAt <- T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" <$> getCurrentTime
  let msg = ChatMessage
        { chatMsgId       = msgId,
          chatMsgRoomId   = clientRoomId sender,
          chatMsgUserId   = clientUserId sender,
          chatMsgUserName = clientUserName sender,
          chatMsgText     = msgText,
          chatMsgSentAt   = sentAt
        }
  atomically $ modifyTVar store $ Map.insertWith (++) (clientRoomId sender) [msg]
  clients <- atomically $ Map.findWithDefault [] (clientRoomId sender) <$> readTVar rooms
  let payload =
        encode $
          object
            [ "event" .= ("message.broadcast" :: Text),
              "data"
                .= object
                  [ "messageId" .= msgId,
                    "roomId" .= clientRoomId sender,
                    "sender"
                      .= object
                        [ "userId" .= clientUserId sender,
                          "userName" .= clientUserName sender
                        ],
                    "text" .= msgText,
                    "sentAt" .= sentAt
                  ]
            ]
  forM_ clients $ \c -> WS.sendTextData (clientConn c) payload

removeClient :: RoomState -> IORef (Maybe ConnectedClient) -> IO ()
removeClient rooms clientRef = do
  mClient <- readIORef clientRef
  case mClient of
    Nothing -> return ()
    Just client ->
      atomically $
        modifyTVar rooms $
          Map.adjust
            (filter (\c -> clientConnId c /= clientConnId client))
            (clientRoomId client)
