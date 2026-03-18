{-# LANGUAGE OverloadedStrings #-}

module App.Middleware.TokenAuth
  ( tokenAuth,
  )
where

import App.DB.RedisPool (withRedisConn)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BS8
import Database.Redis (Connection, get)
import Network.HTTP.Types (hAuthorization, status401)
import Network.Wai (Middleware, Request, Response, rawPathInfo, requestHeaders, responseLBS)

-- | WAI ミドルウェア: Authorization ヘッダーの Bearer トークンを Redis で検証する
--
-- 型シグネチャ:
--   tokenAuth :: Connection -> Middleware
--   Middleware = Application -> Application
--   Application = Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived
--
-- 検証フロー:
--   0. rawPathInfo が "/login" なら認証をスキップして次のミドルウェアへ
--   1. requestHeaders で "Authorization: Bearer <token>" を取り出す
--   2. Redis の get でトークンキーを検索 → Right (Just _) なら有効
--   3. 有効 → app req respond (次のミドルウェアへ委譲)
--   4. 無効 or ヘッダーなし → 401 Unauthorized を即返す
tokenAuth :: Connection -> Middleware
tokenAuth conn app req respond
  | rawPathInfo req == "/login" = app req respond
  | otherwise =
      case extractBearerToken req of
        Nothing -> respond unauthorized
        Just tok -> do
          result <- withRedisConn conn (get tok)
          case result of
            Right (Just _) -> app req respond
            _ -> respond unauthorized

-- | Request から Bearer トークンのバイト列を取り出す
--
-- "Authorization: Bearer 44f9e43b-535d-4dc8-ad52-7fdf59aa4905"
--   → Just "44f9e43b-535d-4dc8-ad52-7fdf59aa4905"
-- ヘッダーなし / Bearer プレフィックスなし → Nothing
--
-- requestHeaders :: Request -> [(HeaderName, ByteString)]
-- hAuthorization :: HeaderName  (= CI ByteString)
extractBearerToken :: Request -> Maybe BS.ByteString
extractBearerToken req =
  case lookup hAuthorization (requestHeaders req) of
    Nothing -> Nothing
    Just val ->
      let prefix = "Bearer "
       in if BS8.isPrefixOf prefix val
            then Just (BS.drop (BS8.length prefix) val)
            else Nothing

-- | 401 Unauthorized レスポンス (プレーンテキスト)
unauthorized :: Response
unauthorized =
  responseLBS status401 [("Content-Type", "text/plain")] "Unauthorized"
