module Main where

import App.Config (Config (..))
import App.DB (createMSSQLPool)
import App.DB.RedisPool (createRedisConn)
import App.DB.SQLiteDB (initDB)
import App.Server (runServant)
import qualified Database.MSSQLServer.Connection as MSSQL
import qualified Database.Redis as Redis

main :: IO ()
main = do
  let servantConfig = Config {port = 8081, host = "localhost"}
  print servantConfig

  let sqliteDbName = "mydb.db"
  initDB sqliteDbName

  let sqlserverInfo =
        MSSQL.defaultConnectInfo
          { MSSQL.connectHost = "127.0.0.1",
            MSSQL.connectPort = "1433",
            MSSQL.connectDatabase = "master",
            MSSQL.connectUser = "sa",
            MSSQL.connectPassword = "MyPass@word1"
          }

  -- プールを生成 (最大 10 コネクション)
  sqlserverPool <- createMSSQLPool sqlserverInfo 10

  let redisInfo =
        Redis.defaultConnectInfo
          { Redis.connectHost = "localhost",
            Redis.connectPort = Redis.PortNumber 6379,
            Redis.connectAuth = Nothing
          }

  redisConn <- createRedisConn redisInfo

  runServant servantConfig sqliteDbName sqlserverPool redisConn
