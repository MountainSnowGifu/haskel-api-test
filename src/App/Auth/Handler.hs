{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Auth.Handler
  ( LoginAPI,
    loginHandler,
  )
where

import App.Auth.UserStore (User (..), userDB)
import App.Infrastructure.DB.Redis (withRedisConn)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Map as Map
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Data.UUID (toText)
import Data.UUID.V4 (nextRandom)
import Database.Redis (Connection, expire, set)
import GHC.Generics (Generic)
import Servant

-- | ログインリクエストのボディ型
--
--   JSON: { "username": "john", "password": "shhhh" }
data LoginRequest = LoginRequest
  { username :: T.Text,
    password :: T.Text
  }
  deriving (Show, Generic)

instance FromJSON LoginRequest

-- | 発行されたトークンのレスポンス型
--
--   JSON: { "token": "550e8400-e29b-41d4-a716-446655440000" }
newtype TokenResponse = TokenResponse
  { token :: T.Text
  }
  deriving (Show, Generic)

instance ToJSON TokenResponse

-- | POST /login :> ReqBody '[JSON] LoginRequest :> Post '[JSON] TokenResponse
type LoginAPI = "login" :> ReqBody '[JSON] LoginRequest :> Post '[JSON] TokenResponse

-- | UUID v4 でトークンを生成する
--
--   生成例: "550e8400-e29b-41d4-a716-446655440000"
--   nextRandom :: IO UUID  (Data.UUID.V4)
--   toText     :: UUID -> Text  (Data.UUID)
generateToken :: IO T.Text
generateToken = toText <$> nextRandom

-- | ログインハンドラー
--
--   1. userDB で username/password を照合
--   2. 認証成功 → トークンを生成して Redis に保存（TTL: 3600秒）
--   3. TokenResponse を返す
--   4. 認証失敗 → 401 Unauthorized
loginHandler :: Connection -> LoginRequest -> Handler TokenResponse
loginHandler conn req = do
  let uname = username req
      pwd = password req
  case Map.lookup uname userDB of
    Nothing ->
      throwError err401 {errBody = "User not found"}
    Just u ->
      if pass u == pwd
        then do
          tok <- liftIO generateToken
          liftIO $ withRedisConn conn $ do
            _ <- set (encodeUtf8 tok) (encodeUtf8 uname)
            _ <- expire (encodeUtf8 tok) 3600
            return ()
          return $ TokenResponse tok
        else throwError err401 {errBody = "Invalid password"}
