{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Message.UseCase
  ( getMessages,
    postMessage,
  )
where

import App.Domain.Message.Entity (Message)
import App.Domain.Message.Repository (MessageRepo, findAll, save)
import Effectful

-- | 全メッセージを取得するユースケース
--
--   型: (MessageRepo :> es) => Eff es [Message]
--
--   ポイント: DB の種類（SQLite/Postgres 等）を知らない。
--   「MessageRepo エフェクトが使える環境」であれば動く。
getMessages :: (MessageRepo :> es) => Eff es [Message]
getMessages = findAll

-- | メッセージを保存するユースケース
postMessage :: (MessageRepo :> es) => Message -> Eff es ()
postMessage = save
