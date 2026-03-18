{-# LANGUAGE DataKinds #-}

module App.Core.Env
  ( AppMonad,
    nt,
    RegisterEnv (..),
    AppMonadRegister,
    ntRegister,
  )
where

import App.Core.Config (Config)
import App.Infrastructure.DB.Types (MSSQLPool)
import Control.Monad.Except (ExceptT (..))
import Control.Monad.Reader (ReaderT, runReaderT)
import Database.Redis (Connection)
import Effectful
import Effectful.Error.Static (Error, runErrorNoCallStack)
import Effectful.Reader.Static (Reader, runReader)
import Servant (Handler (..), ServerError)

-- ReaderT env Handler の自然変換: env -> AppM env a -> Handler a
-- 実体は flip runReaderT
runApp :: env -> ReaderT env Handler a -> Handler a
runApp = flip runReaderT

-- カスタムモナド: Config を環境として持つ ReaderT
type AppMonad = ReaderT Config Handler

-- AppM を Handler に変換する自然変換
nt :: Config -> AppMonad a -> Handler a
nt = runApp

-- MSSQLPool と Redis Connection をまとめた環境
data RegisterEnv = RegisterEnv
  { sqlPool :: MSSQLPool,
    sqlRedis :: Connection
  }

-- effectful 版: エフェクトリストに Reader と Error と IOE を持つ
type AppMonadRegister = Eff '[Reader RegisterEnv, Error ServerError, IOE]

-- エフェクトを順に解釈して Handler に変換
ntRegister :: RegisterEnv -> AppMonadRegister a -> Handler a
ntRegister env action =
  Handler $
    ExceptT $
      runEff $ -- Eff '[IOE] (Either ServerError a) → IO (Either ServerError a)
        runErrorNoCallStack $ -- Eff '[Error ServerError, IOE] a  → Eff '[IOE] (Either ServerError a)
          runReader env action -- Eff '[Reader RegisterEnv, ...] a → Eff '[...] a