{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.Chat.ChatSTM
  ( RoomState,
    newRoomState,
    MessageStore,
    newMessageStore,
    runChatRepo,
  )
where

import App.Domain.Chat.Entity (ChatMessage (..), ConnectedClient (..))
import App.Application.Chat.Repository (ChatRepo (..))
import Control.Concurrent.STM (TVar, atomically, modifyTVar, newTVarIO, readTVar)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | roomId → 接続クライアント一覧
type RoomState = TVar (Map Text [ConnectedClient])

newRoomState :: IO RoomState
newRoomState = newTVarIO Map.empty

-- | roomId → メッセージ履歴（送信順）
type MessageStore = TVar (Map Text [ChatMessage])

newMessageStore :: IO MessageStore
newMessageStore = newTVarIO Map.empty

-- | ChatRepo エフェクトを STM (インメモリ) で解釈するインタープリタ
--
--   TaskSQLServer の runTaskRepo と同じ構造：
--     interpret $ \_ -> \case
--       AddClient client -> liftIO $ atomically $ ...
--
--   型シグネチャ:
--     IOE :> es                   -- IO を実行できるエフェクトが必要
--     => RoomState                -- 接続クライアントの状態 (TVar)
--     -> MessageStore             -- メッセージ履歴の状態 (TVar)
--     -> Eff (ChatRepo : es) a    -- ChatRepo を含むスタック
--     -> Eff es a                 -- ChatRepo を除いたスタック
runChatRepo ::
  (IOE :> es) =>
  RoomState ->
  MessageStore ->
  Eff (ChatRepo : es) a ->
  Eff es a
runChatRepo rooms store = interpret $ \_ -> \case
  AddClient client ->
    liftIO $
      atomically $
        modifyTVar rooms $
          Map.insertWith (++) (clientRoomId client) [client]
  RemoveClient client ->
    liftIO $
      atomically $
        modifyTVar rooms $
          Map.adjust
            (filter (\c -> clientConnId c /= clientConnId client))
            (clientRoomId client)
  GetClients roomId ->
    liftIO $
      atomically $
        Map.findWithDefault [] roomId <$> readTVar rooms
  SaveMessage msg ->
    liftIO $
      atomically $
        modifyTVar store $
          Map.insertWith (++) (chatMsgRoomId msg) [msg]
