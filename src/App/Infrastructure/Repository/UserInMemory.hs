{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.UserInMemory
  ( runUserRepoInMemory,
  )
where

import App.Domain.Auth.Entity (Password (..), User (..), Username (..))
import App.Domain.Auth.Repository (UserRepo (..))
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | テスト用のインメモリユーザーデータ
--
--   旧: App.Auth.UserStore の userDB をここに移動
--   本番では DB を参照するインタープリタ（runUserRepoPostgres 等）に差し替えられる
users :: [User]
users =
  [ User (Username "john") (Password "shhhh") 1,
    User (Username "foo") (Password "bar") 2
  ]

userMap :: Map.Map T.Text User
userMap = Map.fromList [(unUsername (userUsername u), u) | u <- users]

-- | UserRepo エフェクトをインメモリ Map で解釈するインタープリタ
runUserRepoInMemory :: Eff (UserRepo : es) a -> Eff es a
runUserRepoInMemory = interpret $ \_ -> \case
  FindByUsername (Username uname) -> return $ Map.lookup uname userMap
