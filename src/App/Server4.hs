{-# LANGUAGE OverloadedStrings #-}

module App.Server4
  ( server4,
  )
where

import App.API (API4)
import App.DB (MSSQLPool, withMSSQLConn)
import Control.Monad.IO.Class (liftIO)
import Database.MSSQLServer.Connection
import Database.MSSQLServer.Query
import Servant

server4 :: MSSQLPool -> Server API4
server4 pool = postSqlserver :<|> getSqlserver
  where
    postSqlserver :: Handler String
    postSqlserver =
      liftIO $ withMSSQLConn pool $ \conn -> do
        [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
        print i
        return "SQL Server message"

    getSqlserver :: Handler String
    getSqlserver = liftIO $ withMSSQLConn pool $ \conn -> do
      [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
      print i
      return "SQL Server message"