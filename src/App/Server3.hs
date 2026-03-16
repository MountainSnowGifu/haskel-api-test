{-# LANGUAGE OverloadedStrings #-}

module App.Server3
  ( server3,
  )
where

import App.API (API3, Message)
import Control.Monad.IO.Class (liftIO)
import Database.SQLite.Simple (execute, query_, withConnection)
import Database.SQLite.Simple.Types (Only (..))
import Servant

server3 :: FilePath -> Server API3
server3 dbfile = postMessage :<|> getMessages
  where
    postMessage :: Message -> Handler NoContent
    postMessage message = do
      liftIO . withConnection dbfile $ \conn ->
        execute
          conn
          "INSERT INTO messages VALUES (?)"
          (Only message)
      return NoContent

    getMessages :: Handler [Message]
    getMessages = fmap (map fromOnly) . liftIO $
      withConnection dbfile $ \conn ->
        query_ conn "SELECT msg FROM messages"
