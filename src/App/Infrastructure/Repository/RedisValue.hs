{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.RedisValue
  ( runRedisRepo,
  )
where

import App.Domain.Redis.Repository (RedisRepo (..))
import App.Infrastructure.DB.Redis (withRedisConn)
import Control.Exception (throwIO)
import Database.Redis (Connection, get)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | RedisRepo エフェクトを hedis で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es              -- IO を実行できるエフェクトが必要
--     => Connection          -- Redis コネクション
--     -> Eff (RedisRepo : es) a  -- RedisRepo を含むスタック
--     -> Eff es a                -- RedisRepo を除いたスタック
--
--   hedis の get は Either Reply (Maybe ByteString) を返す。
--   Left (Reply エラー) は Infrastructure 層で IO 例外に変換し、
--   Domain の型 Maybe ByteString のみを上位層に公開する。
runRedisRepo ::
  (IOE :> es) =>
  Connection ->
  Eff (RedisRepo : es) a ->
  Eff es a
runRedisRepo conn = interpret $ \_ -> \case
  GetValue key ->
    liftIO $ do
      result <- withRedisConn conn $ get key
      case result of
        Right mval -> return mval
        Left err -> throwIO $ userError (show err)
