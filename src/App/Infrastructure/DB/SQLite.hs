{-# LANGUAGE OverloadedStrings #-}

module App.Infrastructure.DB.SQLite
  ( initDB,
  )
where

import Database.SQLite.Simple (execute_, withConnection)
import Database.SQLite.Simple.Types (Query (..))

initDB :: FilePath -> IO ()
initDB dbfile = withConnection dbfile $ \conn ->
  execute_
    conn
    (Query "CREATE TABLE IF NOT EXISTS messages (msg text not null)")
