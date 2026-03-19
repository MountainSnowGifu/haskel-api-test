{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Auth.UseCase
  ( AuthError (..),
    login,
  )
where

import App.Domain.Auth.Entity (Password (..), Token (..), User (..), Username)
import App.Domain.Auth.Repository (TokenStore, UserRepo, findByUsername, storeToken)
import Data.UUID (toText)
import Data.UUID.V4 (nextRandom)
import Effectful

-- | 認証ドメインのエラー型
--
--   Presentation 層でこれを HTTP エラーにマッピングする
data AuthError = UserNotFound | InvalidPassword
  deriving (Show, Eq)

-- | セッション有効期限（秒）
--
--   これは「1時間でセッションが切れる」というビジネスルールなので
--   Application 層に置く
tokenTTL :: Integer
tokenTTL = 3600

-- | UUID v4 トークンを生成する IO アクション
generateToken :: IO Token
generateToken = Token . toText <$> nextRandom

-- | ログインユースケース
--
--   型: (UserRepo :> es, TokenStore :> es, IOE :> es)
--        => Username -> Password -> Eff es (Either AuthError Token)
--
--   フロー:
--     1. UserRepo でユーザーを検索 → Nothing なら UserNotFound
--     2. パスワードを照合 → 不一致なら InvalidPassword
--     3. トークン生成（IO）→ TokenStore で保存
--     4. Right Token を返す
--
--   ポイント: HTTP も Redis の詳細も知らない。
--   「UserRepo と TokenStore が使える環境」であれば動く。
login ::
  (UserRepo :> es, TokenStore :> es, IOE :> es) =>
  Username ->
  Password ->
  Eff es (Either AuthError Token)
login username password = do
  mUser <- findByUsername username
  case mUser of
    Nothing -> return $ Left UserNotFound
    Just user ->
      if userPassword user == password
        then do
          tok <- liftIO generateToken
          storeToken tok username tokenTTL
          return $ Right tok
        else return $ Left InvalidPassword
