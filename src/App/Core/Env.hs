module App.Core.Env
  ( AppM,
    nt,
    RegisterEnv (..),
    AppMSql,
    ntRegister,
  )
where

import App.Core.Config (Config)
import App.Infrastructure.DB.Types (MSSQLPool)
import Control.Monad.Reader (ReaderT, runReaderT)
import Database.Redis (Connection)
import Servant (Handler)

-- ReaderT env Handler の自然変換: env -> AppM env a -> Handler a
-- 実体は flip runReaderT
runApp :: env -> ReaderT env Handler a -> Handler a
runApp = flip runReaderT

-- カスタムモナド: Config を環境として持つ ReaderT
type AppM = ReaderT Config Handler

-- AppM を Handler に変換する自然変換
nt :: Config -> AppM a -> Handler a
nt = runApp

-- MSSQLPool と Redis Connection をまとめた環境
data RegisterEnv = RegisterEnv
  { sqlPool :: MSSQLPool,
    sqlRedis :: Connection
  }

-- カスタムモナド: RegisterEnv を環境として持つ ReaderT
type AppMSql = ReaderT RegisterEnv Handler

-- AppMSql を Handler に変換する自然変換
ntRegister :: RegisterEnv -> AppMSql a -> Handler a
ntRegister = runApp