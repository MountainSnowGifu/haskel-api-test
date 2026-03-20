{-# LANGUAGE OverloadedStrings #-}

module App.Middleware.TokenAuth
  ( mkTokenAuthHandler,
  )
where

import App.Domain.Auth.Entity (Username (..))
import App.Infrastructure.DB.Redis (withRedisConn)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BS8
import Data.Text.Encoding (decodeUtf8)
import Database.Redis (Connection, get)
import Network.HTTP.Types (hAuthorization)
import Network.Wai (Request, requestHeaders)
import Servant (err401, throwError)
import Servant.Server.Experimental.Auth (AuthHandler, mkAuthHandler)

-- | Servant AuthHandler: Bearer トークンを Redis で検証し Username を返す
--
-- 型シグネチャ:
--   mkTokenAuthHandler :: Connection -> AuthHandler Request Username
--   AuthHandler req val = AuthHandler { unAuthHandler :: req -> Handler val }
--
-- 検証フロー:
--   1. requestHeaders から "Authorization: Bearer <token>" を取り出す
--   2. Redis の get でトークンキーを検索 → Right (Just uname) なら有効
--   3. 有効 → Username (decodeUtf8 uname) を返す
--   4. 無効 or ヘッダーなし → 401 を throwError
--
-- WAI Middleware との違い:
--   Middleware は Bool でガードするだけ。AuthHandler は値を返す。
--   Servant がその値をハンドラの引数として型安全に渡す。
mkTokenAuthHandler :: Connection -> AuthHandler Request Username
mkTokenAuthHandler conn = mkAuthHandler $ \req ->
  case extractBearerToken req of
    Nothing -> throwError err401
    Just tok -> do
      result <- liftIO $ withRedisConn conn (get tok)
      case result of
        Right (Just uname) -> return $ Username (decodeUtf8 uname)
        _ -> throwError err401

-- | Request から Bearer トークンのバイト列を取り出す
--
-- "Authorization: Bearer 44f9e43b-535d-4dc8-ad52-7fdf59aa4905"
--   → Just "44f9e43b-535d-4dc8-ad52-7fdf59aa4905"
-- ヘッダーなし / Bearer プレフィックスなし → Nothing
extractBearerToken :: Request -> Maybe BS.ByteString
extractBearerToken req =
  case lookup hAuthorization (requestHeaders req) of
    Nothing -> Nothing
    Just val ->
      let prefix = "Bearer "
       in if BS8.isPrefixOf prefix val
            then Just (BS.drop (BS8.length prefix) val)
            else Nothing
