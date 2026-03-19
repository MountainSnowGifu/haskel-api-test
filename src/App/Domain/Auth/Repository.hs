{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.Auth.Repository
  ( UserRepo (..),
    findByUsername,
    TokenStore (..),
    storeToken,
  )
where

import App.Domain.Auth.Entity (Token, User, Username)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | ユーザー検索エフェクト
--
--   FindByUsername :: Username -> UserRepo m (Maybe User)
--     Username を渡すと Maybe User が返る操作を宣言する
--     「どう取得するか」はインタープリタ（Infrastructure）が決める
data UserRepo :: Effect where
  FindByUsername :: Username -> UserRepo m (Maybe User)

type instance DispatchOf UserRepo = Dynamic

findByUsername :: (UserRepo :> es) => Username -> Eff es (Maybe User)
findByUsername = send . FindByUsername

-- | トークン保存エフェクト
--
--   StoreToken :: Token -> Username -> Integer -> TokenStore m ()
--     Integer は TTL（秒）。Application 層がセッション有効期限を決める。
data TokenStore :: Effect where
  StoreToken :: Token -> Username -> Integer -> TokenStore m ()

type instance DispatchOf TokenStore = Dynamic

storeToken :: (TokenStore :> es) => Token -> Username -> Integer -> Eff es ()
storeToken tok uname ttl = send (StoreToken tok uname ttl)
