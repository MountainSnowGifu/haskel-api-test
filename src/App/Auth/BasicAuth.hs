{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Auth.BasicAuth
  ( AuthAPI,
    User (..),
    userDB,
    checkBasicAuth,
  )
where

import qualified Data.Map as Map
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)
import Servant

type Username = T.Text

type Password = T.Text

type Website = T.Text

data User = User
  { user :: Username,
    pass :: Password,
    site :: Website
  }
  deriving (Eq, Show)

-- postgres 接続やファイルなど、何でも使える汎用的な型
type UserDB = Map.Map Username User

-- ユーザーリストから UserDB を構築する
createUserDB :: [User] -> UserDB
createUserDB users = Map.fromList [(user u, u) | u <- users]

-- テスト用ユーザーデータベース
userDB :: UserDB
userDB =
  createUserDB
    [ User "john" "shhhh" "john.com",
      User "foo" "bar" "foobar.net"
    ]

-- Basic 認証で保護された 'GET /mysite' エンドポイント
type AuthAPI = BasicAuth "Web Study API" User :> "mysite" :> Get '[JSON] Website

{- 複数のエンドポイントをまとめて保護する場合:
type API = BasicAuth "Web Study API" User :>
    ( "foo" :> Get '[JSON] Foo
 :<|> "bar" :> Get '[JSON] Bar
    )
-}

-- api :: Proxy API
-- api = Proxy

-- server :: Server API
-- server usr = return (site usr)

-- UserDB を受け取り、Basic 認証の資格情報をデータベースと照合する関数を返す
checkBasicAuth :: UserDB -> BasicAuthCheck User
checkBasicAuth db = BasicAuthCheck $ \basicAuthData ->
  let username = decodeUtf8 (basicAuthUsername basicAuthData)
      password = decodeUtf8 (basicAuthPassword basicAuthData)
   in case Map.lookup username db of
        Nothing -> return NoSuchUser
        Just u ->
          if pass u == password
            then return (Authorized u)
            else return BadPassword

-- runApp :: UserDB -> IO ()
-- runApp db = run 8080 (serveWithContext api ctx server)
--   where
--     ctx = checkBasicAuth db :. EmptyContext

-- runServant :: IO ()
-- runServant = runApp userDB
