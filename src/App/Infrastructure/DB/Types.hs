module App.Infrastructure.DB.Types
  ( MSSQLPool,
  )
where

import Data.Pool (Pool)
import Database.MSSQLServer.Connection (Connection)

-- | コネクションプールの型エイリアス
--
--   Pool Connection は「Connection を貸し出すプール」
--   Pool 自体は IORef などで内部状態を持つ不透明な値
type MSSQLPool = Pool Connection
