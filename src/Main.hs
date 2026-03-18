module Main where

import App.Config (Config (..))
import App.DB (createMSSQLPool)
import App.DB.SQLiteDB (initDB)
import App.Server (runServant)
import Database.MSSQLServer.Connection

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

  let dbname = "mydb.db"
  initDB dbname

  runServant config dbname pool
