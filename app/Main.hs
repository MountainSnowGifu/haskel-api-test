module Main where

import App.Core.Config (Config (..), LogFormat (..), LogLevel (..))
import App.Infrastructure.DB.Redis (createRedisConn)
import App.Infrastructure.DB.SQLite (initDB)
import App.Infrastructure.DB.SqlServer (createMSSQLPool)
import App.Infrastructure.DB.Types (SqliteDb (..))
import App.Server.Router (runServant)
import qualified Database.MSSQLServer.Connection as MSSQL
import qualified Database.Redis as Redis

main :: IO ()
main = do
  let servantConfig =
        Config
          { port = 8081,
            host = "localhost",
            logLevel = Debug,
            logFormat = Json,
            logFilePath = "access.log"
          }
  print servantConfig

  let sqliteDbName = SqliteDb "BT.db"
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
