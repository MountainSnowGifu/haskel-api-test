{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Server.API
  ( API,
    combinedAPI,
    wsHandler,
    newRoomState,
    RoomState,
  )
where

import App.Domain.Auth.Entity (User)
import App.Presentation.Auth.API (LoginAPI)
import App.Presentation.Greeting.API (GreetingAPI)
import App.Presentation.Marketing.API (MarketingAPI)
import App.Presentation.Message.API (MessageAPI)
import App.Presentation.Person.API (PersonAPI)
import App.Presentation.Redis.API (RedisAPI)
import App.Presentation.SqlServerDemo.API (SqlServerAPI)
import App.Presentation.Task.API (TaskAPI)
import Control.Concurrent.STM (TVar, atomically, modifyTVar, newTVarIO, readTVar)
import Control.Exception (finally)
import Control.Monad (forM_, forever)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON, Result (..), Value (..), decode, encode, fromJSON, object, (.=))
import Data.Aeson.KeyMap qualified as KM
import Data.ByteString.Lazy (ByteString)
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 (nextRandom)
import GHC.Generics (Generic)
import Network.WebSockets qualified as WS
import Servant
import Servant.API.WebSocket
import Servant.Server.Experimental.Auth (AuthServerData)

-- | AuthProtect "token-auth" が解決する値の型を宣言する
--
-- これにより Servant は AuthHandler Request User を
-- Context から探してハンドラに渡すことができる。
type instance AuthServerData (AuthProtect "token-auth") = User

type API = LoginAPI :<|> MarketingAPI :<|> PersonAPI :<|> MessageAPI :<|> SqlServerAPI :<|> RedisAPI :<|> GreetingAPI :<|> TaskAPI :<|> ChatAPI

type ChatAPI =
  "chat" :> "ws" :> WebSocket

-- ---------------------------------------------------------------------------
-- ルーム状態
-- ---------------------------------------------------------------------------

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
-- エラー
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
-- バリデーション
-- ---------------------------------------------------------------------------

data ValidationError = EmptyText | TextTooLong

validateMessageSend :: MessageSendData -> Either ValidationError MessageSendData
validateMessageSend d
  | T.null (text d) = Left EmptyText
  | T.length (text d) > 1000 = Left TextTooLong
  | otherwise = Right d

-- ---------------------------------------------------------------------------
-- WebSocket ハンドラ
-- ---------------------------------------------------------------------------

wsHandler :: RoomState -> WS.Connection -> Handler ()
wsHandler rooms conn = liftIO $ do
  clientRef <- newIORef Nothing
  finally
    ( forever $ do
        raw <- WS.receiveData conn :: IO ByteString
        case decode raw of
          Just (Object km) -> handleEvent rooms conn clientRef km
          _ -> return ()
    )
    (removeClient rooms clientRef)

handleEvent :: RoomState -> WS.Connection -> IORef (Maybe ConnectedClient) -> KM.KeyMap Value -> IO ()
handleEvent rooms conn clientRef km = case KM.lookup "event" km of
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
        Success msgData -> handleMessageSend rooms conn clientRef msgData
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

handleMessageSend :: RoomState -> WS.Connection -> IORef (Maybe ConnectedClient) -> MessageSendData -> IO ()
handleMessageSend rooms conn clientRef msgData =
  case validateMessageSend msgData of
    Left EmptyText -> sendError conn MessageInvalid "text は必須です"
    Left TextTooLong -> sendError conn MessageInvalid "text は1000文字以内です"
    Right d -> do
      mClient <- readIORef clientRef
      case mClient of
        Nothing -> return ()
        Just sender -> broadcastMessage rooms sender (text d)

broadcastMessage :: RoomState -> ConnectedClient -> Text -> IO ()
broadcastMessage rooms sender msgText = do
  msgId <- UUID.toText <$> nextRandom
  sentAt <- T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" <$> getCurrentTime
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

combinedAPI :: Proxy API
combinedAPI = Proxy
