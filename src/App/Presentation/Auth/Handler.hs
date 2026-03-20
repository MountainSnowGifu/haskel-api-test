{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Auth.Handler
  ( loginHandler,
  )
where

import App.Application.Auth.UseCase (AuthError (..), login)
import App.Domain.Auth.Entity (Password (..), Token (..), Username (..))
import App.Infrastructure.Repository.TokenRedis (runTokenRedis)
import App.Infrastructure.Repository.UserInMemory (runUserRepoInMemory)
import App.Presentation.Auth.API (LoginRequest (..), TokenResponse (..))
import Control.Monad.IO.Class (liftIO)
import Database.Redis (Connection)
import Effectful (runEff)
import Servant

-- | ログインハンドラ
--
--   型の流れ:
--     Eff '[UserRepo, TokenStore, IOE] (Either AuthError Token)
--       → (runUserRepoInMemory) → Eff '[TokenStore, IOE] (Either AuthError Token)
--       → (runTokenRedis conn)  → Eff '[IOE] (Either AuthError Token)
--       → (runEff)              → IO (Either AuthError Token)
--       → (liftIO)              → Handler (Either AuthError Token)
--     そして AuthError を HTTP エラーにマッピング
loginHandler :: Connection -> LoginRequest -> Handler TokenResponse
loginHandler conn req = do
  let uname = Username (username req)
      pwd = Password (password req)
  result <-
    liftIO $
      runEff $
        runUserRepoInMemory $
          runTokenRedis conn $
            login uname pwd
  case result of
    Left UserNotFound -> throwError err401 {errBody = "User not found"}
    Left InvalidPassword -> throwError err401 {errBody = "Invalid password"}
    Right (Token tok) -> return $ TokenResponse tok
