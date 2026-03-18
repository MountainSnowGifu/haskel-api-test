{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Auth.UserStore
  ( User (..),
    userDB,
  )
where

import qualified Data.Map as Map
import qualified Data.Text as T

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
