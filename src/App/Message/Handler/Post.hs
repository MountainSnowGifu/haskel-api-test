{-# LANGUAGE OverloadedStrings #-}

module App.Message.Handler.Post
  ( postMessage,
  )
where

import App.Message.API (Message)
import Control.Monad.IO.Class (liftIO)
import Database.SQLite.Simple (execute, withConnection)
import Database.SQLite.Simple.Types (Only (..))
import Servant (Handler, NoContent (..))

postMessage :: FilePath -> Message -> Handler NoContent
postMessage dbfile message = do
  liftIO . withConnection dbfile $ \conn ->
    execute
      conn
      "INSERT INTO messages VALUES (?)"
      (Only message)
  return NoContent
