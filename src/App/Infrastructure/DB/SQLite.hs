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
    ( Query
        "CREATE TABLE IF NOT EXISTS records \
        \(id INTEGER PRIMARY KEY, \
        \user_id INTEGER NOT NULL, \
        \type TEXT NOT NULL , \
        \category TEXT NOT NULL, \
        \amount INTEGER NOT NULL, \
        \date TEXT NOT NULL, \
        \memo TEXT NOT NULL)"
    )
