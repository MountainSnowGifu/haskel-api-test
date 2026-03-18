module App.DB.SqlserverPool
  ( createMSSQLPool,
    withMSSQLConn,
  )
where

import App.DB.Types (MSSQLPool)
import Data.Pool (defaultPoolConfig, newPool, withResource)
import Database.MSSQLServer.Connection

-- | プールを生成する
--
--   newPool :: PoolConfig a -> IO (Pool a)
--
--   defaultPoolConfig :: IO a -> (a -> IO ()) -> Double -> Int -> PoolConfig a
--     引数順: acquire, release, アイドルタイムアウト(秒), 最大コネクション数
createMSSQLPool ::
  -- | 接続情報
  ConnectInfo ->
  -- | 最大コネクション数
  Int ->
  IO MSSQLPool
createMSSQLPool info maxConns =
  newPool $
    defaultPoolConfig
      (connectWithoutEncryption info) -- acquire
      close -- release
      30 -- アイドルタイムアウト (秒)
      maxConns -- 最大コネクション数

-- | プールからコネクションを借りてアクションを実行する
--
--   withResource :: Pool a -> (a -> IO b) -> IO b
--   bracket パターンで acquire / release が保証される
withMSSQLConn :: MSSQLPool -> (Connection -> IO a) -> IO a
withMSSQLConn = withResource
