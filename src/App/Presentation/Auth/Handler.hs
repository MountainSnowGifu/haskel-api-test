{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Auth.Handler
  ( loginHandler,
  )
where

import App.Application.Auth.UseCase (AuthError (..), login)
import App.Domain.Auth.Entity (Password (..), Token (..), Username (..))
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Repository.Auth.TokenRedis (runTokenRedis)
import App.Infrastructure.Repository.User.UserSQLServer (runUserRepoSqlServer)
import App.Presentation.Auth.API (LoginRequest (..), TokenResponse (..))
import Control.Monad.IO.Class (liftIO)
import Database.Redis (Connection)
import Effectful (runEff)
import Servant

-- | ログインハンドラ
--
--   フロー:
--     1. login UseCase が UserRepo (SQL Server) で username を検索
--     2. パスワード照合 → トークン発行 → Redis に userId を保存
loginHandler :: MSSQLPool -> Connection -> LoginRequest -> Handler TokenResponse
loginHandler pool redisConn req = do
  let uname = Username (username req)
      pwd = Password (password req)
  result <-
    liftIO $
      runEff $
        runUserRepoSqlServer pool $
          runTokenRedis redisConn $
            login uname pwd
  case result of
    Left UserNotFound -> throwError err401 {errBody = "User not found"}
    Left InvalidPassword -> throwError err401 {errBody = "Invalid password"}
    Right (Token tok) -> return $ TokenResponse tok
