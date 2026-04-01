{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Auth.Repository
  ( UserRepo (..),
    findByUserId,
    findByUsername,
    TokenStore (..),
    storeToken,
  )
where

import App.Domain.Auth.Entity (Token, User, UserId, Username)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | ユーザー検索エフェクト
--
--   FindByUserId  : トークン認証時、Redis から取得した UserId で User を引く
--   FindByUsername: ログイン時、username でユーザーを検索する
data UserRepo :: Effect where
  FindByUserId :: UserId -> UserRepo m (Maybe User)
  FindByUsername :: Username -> UserRepo m (Maybe User)

type instance DispatchOf UserRepo = Dynamic

findByUserId :: (UserRepo :> es) => UserId -> Eff es (Maybe User)
findByUserId = send . FindByUserId

findByUsername :: (UserRepo :> es) => Username -> Eff es (Maybe User)
findByUsername = send . FindByUsername

-- | トークン保存エフェクト
data TokenStore :: Effect where
  StoreToken :: Token -> UserId -> Integer -> TokenStore m ()

type instance DispatchOf TokenStore = Dynamic

storeToken :: (TokenStore :> es) => Token -> UserId -> Integer -> Eff es ()
storeToken tok uid ttl = send (StoreToken tok uid ttl)
