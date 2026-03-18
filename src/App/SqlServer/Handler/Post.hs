{-# LANGUAGE OverloadedStrings #-}

module App.SqlServer.Handler.Post
  ( postSqlserver,
  )
where

import App.DB (MSSQLPool, withMSSQLConn)
import Control.Monad.IO.Class (liftIO)
import Database.MSSQLServer.Query
import Servant (Handler)

postSqlserver :: MSSQLPool -> Handler String
postSqlserver pool =
  liftIO $ withMSSQLConn pool $ \conn -> do
    [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
    print i
    return "SQL Server message"
