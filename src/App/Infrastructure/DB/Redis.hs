module App.Infrastructure.DB.Redis
  ( createRedisConn,
    withRedisConn,
  )
where

import Database.Redis (ConnectInfo, Connection, Redis, checkedConnect, runRedis)

-- | Redis コネクションを生成する
--
--   checkedConnect :: ConnectInfo -> IO Connection
--
--   hedis の Connection は内部でコネクションプールを持つ
--   (resource-pool 相当の管理が hedis 内部で行われる)
--
--   ConnectInfo のデフォルト値:
--     defaultConnectInfo = ConnectInfo
--       { connectHost           = "localhost"
--       , connectPort           = PortNumber 6379
--       , connectAuth           = Nothing
--       , connectDatabase       = 0
--       , connectMaxConnections = 50
--       , connectMaxIdleTime    = 30
--       , connectTimeout        = Nothing
--       , connectTLSParams      = Nothing
--       }
createRedisConn ::
  -- | 接続情報
  ConnectInfo ->
  IO Connection
createRedisConn = checkedConnect

-- | コネクションを使って Redis コマンドを実行する
--
--   runRedis :: Connection -> Redis a -> IO a
--
--   Redis a は ReaderT Redis IO a の newtype ラッパー
--   コネクションプールから借りて実行し、終了後に返却する
withRedisConn :: Connection -> Redis a -> IO a
withRedisConn = runRedis
