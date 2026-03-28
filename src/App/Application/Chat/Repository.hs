{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Chat.Repository
  ( ChatRepo (..),
    addClient,
    removeClient,
    getClients,
    saveMessage,
  )
where

import App.Domain.Chat.Entity (ChatMessage, ConnectedClient)
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | Chat ドメインの永続化・状態管理を抽象化する Effect
--
-- TaskRepo と同じ GADT パターン：
--   data TaskRepo :: Effect where
--     GetTask :: Int -> TaskRepo m (Maybe Task)
--   type instance DispatchOf TaskRepo = Dynamic
--
-- 実装（STM / DB など）は Infrastructure 層で提供する。
data ChatRepo :: Effect where
  AddClient    :: ConnectedClient -> ChatRepo m ()
  RemoveClient :: ConnectedClient -> ChatRepo m ()
  GetClients   :: Text            -> ChatRepo m [ConnectedClient]
  SaveMessage  :: ChatMessage     -> ChatRepo m ()

type instance DispatchOf ChatRepo = Dynamic

addClient :: (ChatRepo :> es) => ConnectedClient -> Eff es ()
addClient = send . AddClient

removeClient :: (ChatRepo :> es) => ConnectedClient -> Eff es ()
removeClient = send . RemoveClient

-- | roomId に接続中のクライアント一覧を取得する
getClients :: (ChatRepo :> es) => Text -> Eff es [ConnectedClient]
getClients = send . GetClients

saveMessage :: (ChatRepo :> es) => ChatMessage -> Eff es ()
saveMessage = send . SaveMessage
