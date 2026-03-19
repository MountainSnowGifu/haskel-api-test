{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.Redis.Repository
  ( RedisRepo (..),
    getValue,
  )
where

import Data.ByteString (ByteString)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | RedisRepo エフェクト
--
--   型シグネチャで操作を宣言する。
--   実装（hedis 等）は Infrastructure 層で選択する。
--
--   エラー（Reply）は Infrastructure 層で IO 例外に変換し、
--   Domain では Maybe のみを扱う。
--
--   GetValue :: ByteString -> RedisRepo m (Maybe ByteString)
--     キーを受け取り、値があれば Just、なければ Nothing を返す
data RedisRepo :: Effect where
  GetValue :: ByteString -> RedisRepo m (Maybe ByteString)

type instance DispatchOf RedisRepo = Dynamic

-- | キーに対応する値を取得する
--
--   型: RedisRepo :> es => ByteString -> Eff es (Maybe ByteString)
getValue :: (RedisRepo :> es) => ByteString -> Eff es (Maybe ByteString)
getValue = send . GetValue
