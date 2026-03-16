{-# LANGUAGE OverloadedStrings #-}

module Main where

import App.Config (Config (..))
import App.DB (createMSSQLPool, withMSSQLConn)
import App.Server
import Database.MSSQLServer.Connection
import Database.MSSQLServer.Query
import Database.SQLite.Simple (execute_, withConnection)
import Database.SQLite.Simple.Types hiding (Only)

initDB :: FilePath -> IO ()
initDB dbfile = withConnection dbfile $ \conn ->
  execute_
    conn
    (Query "CREATE TABLE IF NOT EXISTS messages (msg text not null)")

main :: IO ()
main = do
  let config = Config {port = 8081, host = "localhost"}
  print config

  let info =
        defaultConnectInfo
          { connectHost = "127.0.0.1",
            connectPort = "1433",
            connectDatabase = "master",
            connectUser = "sa",
            connectPassword = "MyPass@word1"
          }

  -- プールを生成 (最大 10 コネクション)
  pool <- createMSSQLPool info 10

  -- プールからコネクションを借りてクエリを実行
  -- withMSSQLConn は bracket で囲まれているので例外時も返却される
  withMSSQLConn pool $ \conn -> do
    [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
    print i

  let dbname = "mydb.db"
  initDB dbname

  runServant config dbname pool