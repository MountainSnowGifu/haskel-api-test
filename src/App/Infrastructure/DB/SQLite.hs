{-# LANGUAGE OverloadedStrings #-}

module App.Infrastructure.DB.SQLite
  ( initDB,
  )
where

import App.Infrastructure.DB.Types (SqliteDb (..))
import Database.SQLite.Simple (execute_, withConnection)
import Database.SQLite.Simple.Types (Query (..))

initDB :: SqliteDb -> IO ()
initDB (SqliteDb dbfile) = withConnection dbfile $ \conn ->
  execute_
    conn
    (Query "CREATE TABLE IF NOT EXISTS messages (msg text not null)")
