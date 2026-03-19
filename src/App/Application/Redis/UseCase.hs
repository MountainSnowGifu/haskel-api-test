{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Redis.UseCase
  ( getValue,
  )
where

import qualified App.Domain.Redis.Repository as Domain
import App.Domain.Redis.Repository (RedisRepo)
import Data.ByteString (ByteString)
import Effectful

-- | キーに対応する値を取得するユースケース
--
--   型: (RedisRepo :> es) => ByteString -> Eff es (Maybe ByteString)
--
--   Message の getMessages = findAll と同じ構造。
--   Domain の getValue を UseCase 経由で公開する薄いラッパー。
getValue :: (RedisRepo :> es) => ByteString -> Eff es (Maybe ByteString)
getValue = Domain.getValue
