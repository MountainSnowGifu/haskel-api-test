{-# LANGUAGE OverloadedStrings #-}

module App.API.SqlServerDemo.Handler.Post
  ( postSqlserver,
  )
where

import App.Core.Env (AppMSql, RegisterEnv (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (asks)
import Database.MSSQLServer.Query

postSqlserver :: AppMSql String
postSqlserver = do
  pool <- asks sqlPool
  liftIO $ withMSSQLConn pool $ \conn -> do
    [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
    print i
    return "SQL Server message"
