{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Auth.UseCase
  ( AuthError (..),
    login,
  )
where

import App.Domain.Auth.Entity (Password (..), Token (..), User (..), Username)
import App.Application.Auth.Repository (TokenStore, UserRepo, findByUsername, storeToken)
import Data.UUID (toText)
import Data.UUID.V4 (nextRandom)
import Effectful

data AuthError = UserNotFound | InvalidPassword
  deriving (Show, Eq)

tokenTTL :: Integer
tokenTTL = 36000

generateToken :: IO Token
generateToken = Token . toText <$> nextRandom

-- | ログインユースケース
--
--   型: (UserRepo :> es, TokenStore :> es, IOE :> es) => Username -> Password -> Eff es (Either AuthError Token)
--
--   フロー:
--     1. UserRepo で username を検索 → 見つからなければ UserNotFound
--     2. パスワードを照合 → 不一致なら InvalidPassword
--     3. トークン生成（IO）→ TokenStore で保存
--     4. Right Token を返す
login ::
  (UserRepo :> es, TokenStore :> es, IOE :> es) =>
  Username ->
  Password ->
  Eff es (Either AuthError Token)
login uname inputPwd = do
  mUser <- findByUsername uname
  case mUser of
    Nothing -> return $ Left UserNotFound
    Just user ->
      if userPassword user == inputPwd
        then do
          tok <- liftIO generateToken
          storeToken tok user tokenTTL
          return $ Right tok
        else return $ Left InvalidPassword
