{-# LANGUAGE OverloadedStrings #-}

module App.Middleware.TokenAuth
  ( mkTokenAuthHandler,
  )
where

import App.Domain.Auth.Entity (Password (..), User (..), UserId (..), Username (..))
import App.Infrastructure.DB.Redis (withRedisConn)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BS8
import Database.Redis (Connection, get)
import Network.HTTP.Types (hAuthorization)
import Network.Wai (Request, requestHeaders)
import Servant (err401, throwError)
import Servant.Server.Experimental.Auth (AuthHandler, mkAuthHandler)
import Text.Read (readMaybe)

-- | Servant AuthHandler: Bearer トークンを Redis で検証し User を返す
--
-- 型シグネチャ:
--   mkTokenAuthHandler :: Connection -> AuthHandler Request User
--
-- 検証フロー:
--   1. requestHeaders から "Authorization: Bearer <token>" を取り出す
--   2. Redis の get でトークンキーを検索 → Right (Just val) なら有効
--   3. val を "userId:username" としてパース → User を構築
--   4. 無効 or パース失敗 or ヘッダーなし → 401 を throwError
mkTokenAuthHandler :: Connection -> AuthHandler Request User
mkTokenAuthHandler conn = mkAuthHandler $ \req ->
  case extractBearerToken req of
    Nothing -> throwError err401
    Just tok -> do
      result <- liftIO $ withRedisConn conn (get tok)
      case result of
        Right (Just val) ->
          case readMaybe (BS8.unpack val) of
            Just uid -> return $ User (Username "") (Password "") (UserId uid)
            Nothing -> throwError err401
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
