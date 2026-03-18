{-# LANGUAGE OverloadedStrings #-}

module App.SqlServer.Handler.Get
  ( getSqlserver,
  )
where

import App.DB (MSSQLPool, withMSSQLConn)
import Control.Monad.IO.Class (liftIO)
import Database.MSSQLServer.Query
import Servant (Handler)

getSqlserver :: MSSQLPool -> Handler String
getSqlserver pool =
  liftIO $ withMSSQLConn pool $ \conn -> do
    [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
    print i
    return "SQL Server message"
