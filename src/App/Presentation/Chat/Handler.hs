{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Chat.Handler
  ( ConnStore,
    newConnStore,
    wsHandler,
  )
where

import App.Application.Chat.Command (MessageSendCommand (..))
import App.Application.Chat.UseCase (ValidationError (..), disconnectClient, initConnection, storeMessage, validateMessageSend)
import App.Domain.Chat.Entity (ChatMessage (..), ConnectedClient (..), ErrorCode (..), errorCodeText)
import App.Infrastructure.Repository.ChatSTM (MessageStore, RoomState, runChatRepo)
import App.Presentation.Chat.Request (ConnectionInitRequest, MessageSendRequest, toConnectionInitCommand, toMessageSendCommand)
import App.Presentation.Chat.Response (toBroadcastResponse, toConnectionAckResponse)
import Control.Concurrent.STM (TVar, atomically, modifyTVar, newTVarIO, readTVarIO)
import Control.Exception (finally)
import Control.Monad (forever, forM_)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON, Result (..), Value (..), decode, encode, fromJSON, object, (.=))
import Data.Aeson.KeyMap qualified as KM
import Data.ByteString.Lazy (ByteString)
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Effectful (runEff)
import Network.WebSockets qualified as WS
import Servant (Handler)

-- ---------------------------------------------------------------------------
-- ConnStore: connId → WS.Connection の対応表（Presentation 層で管理）
-- ---------------------------------------------------------------------------

type ConnStore = TVar (Map Text WS.Connection)

newConnStore :: IO ConnStore
newConnStore = newTVarIO Map.empty

-- ---------------------------------------------------------------------------
-- WS 応答ヘルパー
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

handleConnectionInit ::
  RoomState ->
  MessageStore ->
  ConnStore ->
  WS.Connection ->
  IORef (Maybe ConnectedClient) ->
  ConnectionInitRequest ->
  IO ()
handleConnectionInit rooms store connStore conn clientRef req = do
  -- UseCase が ConnectedClient を返す。IORef への書き込みは Handler の責務。
  client <- runEff $ runChatRepo rooms store $ initConnection (toConnectionInitCommand req)
  writeIORef clientRef (Just client)
  atomically $ modifyTVar connStore $ Map.insert (clientConnId client) conn
  WS.sendTextData conn $ encode $ toConnectionAckResponse client

handleMessageSend ::
  RoomState ->
  MessageStore ->
  ConnStore ->
  WS.Connection ->
  IORef (Maybe ConnectedClient) ->
  MessageSendRequest ->
  IO ()
handleMessageSend rooms store connStore conn clientRef req =
  case validateMessageSend (toMessageSendCommand req) of
    Left EmptyText -> sendError conn MessageInvalid "text は必須です"
    Left TextTooLong -> sendError conn MessageInvalid "text は1000文字以内です"
    Right cmd -> do
      mClient <- readIORef clientRef
      case mClient of
        Nothing -> return ()
        Just sender -> do
          (msg, clients) <- runEff $ runChatRepo rooms store $ storeMessage sender (cmdText cmd)
          let payload = encode $ toBroadcastResponse msg
          connMap <- readTVarIO connStore
          forM_ clients $ \c ->
            case Map.lookup (clientConnId c) connMap of
              Just wsConn -> WS.sendTextData wsConn payload
              Nothing -> return ()

-- | JSON イベントを種別に応じてディスパッチする
handleEvent ::
  RoomState ->
  MessageStore ->
  ConnStore ->
  WS.Connection ->
  IORef (Maybe ConnectedClient) ->
  KM.KeyMap Value ->
  IO ()
handleEvent rooms store connStore conn clientRef km = case KM.lookup "event" km of
  Just (String "ping") ->
    WS.sendTextData conn $
      encode $
        object
          [ "event" .= ("pong" :: Text),
            "data" .= object []
          ]
  Just (String "connection.init") ->
    dispatch (handleConnectionInit rooms store connStore conn clientRef)
  Just (String "message.send") ->
    dispatch (handleMessageSend rooms store connStore conn clientRef)
  _ -> return ()
  where
    dispatch :: (FromJSON a) => (a -> IO ()) -> IO ()
    dispatch f = case KM.lookup "data" km of
      Just dataVal -> case fromJSON dataVal of
        Success req -> f req
        Error _ -> return ()
      Nothing -> return ()

-- ---------------------------------------------------------------------------
-- エントリポイント
-- ---------------------------------------------------------------------------

wsHandler :: RoomState -> MessageStore -> ConnStore -> WS.Connection -> Handler ()
wsHandler rooms store connStore conn = liftIO $ do
  clientRef <- newIORef Nothing
  finally
    ( forever $ do
        raw <- WS.receiveData conn :: IO ByteString
        case decode raw of
          Just (Object km) -> handleEvent rooms store connStore conn clientRef km
          _ -> return ()
    )
    ( do
        mClient <- readIORef clientRef
        case mClient of
          Nothing -> return ()
          Just client -> do
            atomically $ modifyTVar connStore $ Map.delete (clientConnId client)
            runEff $ runChatRepo rooms store $ disconnectClient client
    )
