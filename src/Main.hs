{-# LANGUAGE OverloadedStrings #-}

module Main where

import App.Config (Config (..))
import App.Server
import Database.SQLite.Simple (execute_, withConnection)
import Database.SQLite.Simple.Types

initDB :: FilePath -> IO ()
initDB dbfile = withConnection dbfile $ \conn ->
  execute_
    conn
    (Query "CREATE TABLE IF NOT EXISTS messages (msg text not null)")

main :: IO ()
main = do
  let config = Config {port = 8081, host = "localhost"}
  print config

  let dbname = "mydb.db"
  initDB dbname

  runServant config dbname