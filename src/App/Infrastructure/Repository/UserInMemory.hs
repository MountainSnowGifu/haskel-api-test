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

import App.Domain.Auth.Entity (Password (..), User (..), UserId (..), Username (..))
import App.Domain.Auth.Repository (UserRepo (..))
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

users :: [User]
users =
  [ User (Username "john") (Password "shhhh") (UserId 1),
    User (Username "foo") (Password "bar") (UserId 2)
  ]

userMap :: Map.Map T.Text User
userMap = Map.fromList [(unUsername (userUsername u), u) | u <- users]

userIdMap :: Map.Map Int User
userIdMap = Map.fromList [(unUserId (userUserId u), u) | u <- users]

-- | UserRepo エフェクトをインメモリ Map で解釈するインタープリタ
runUserRepoInMemory :: Eff (UserRepo : es) a -> Eff es a
runUserRepoInMemory = interpret $ \_ -> \case
  FindByUserId (UserId uid) -> return $ Map.lookup uid userIdMap
  FindByUsername (Username uname) -> return $ Map.lookup uname userMap
