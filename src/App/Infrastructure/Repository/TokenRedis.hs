{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.TokenRedis
  ( runTokenRedis,
  )
where

import App.Domain.Auth.Entity (Token (..), Username (..))
import App.Domain.Auth.Repository (TokenStore (..))
import App.Infrastructure.DB.Redis (withRedisConn)
import Data.Text.Encoding (encodeUtf8)
import Database.Redis (Connection, expire, set)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | TokenStore エフェクトを Redis で解釈するインタープリタ
--
--   TTL はエフェクト呼び出し側（Application 層）から受け取る。
--   ここでは Redis の set/expire コマンドに変換するだけ。
runTokenRedis ::
  (IOE :> es) =>
  Connection ->
  Eff (TokenStore : es) a ->
  Eff es a
runTokenRedis conn = interpret $ \_ -> \case
  StoreToken (Token tok) (Username uname) ttl ->
    liftIO $ withRedisConn conn $ do
      _ <- set (encodeUtf8 tok) (encodeUtf8 uname)
      _ <- expire (encodeUtf8 tok) ttl
      return ()
