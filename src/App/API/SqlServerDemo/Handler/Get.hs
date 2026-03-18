{-# LANGUAGE OverloadedStrings #-}

module App.API.SqlServerDemo.Handler.Get
  ( getSqlserver,
  )
where

import App.Core.Env (AppMonadRegister, RegisterEnv (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import Control.Monad.IO.Class (liftIO)
import Database.MSSQLServer.Query
import Effectful.Reader.Static (asks)

getSqlserver :: AppMonadRegister String
getSqlserver = do
  pool <- asks sqlPool
  liftIO $ withMSSQLConn pool $ \conn -> do
    [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
    print i
    return "SQL Server message"
