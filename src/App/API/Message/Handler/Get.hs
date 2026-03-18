{-# LANGUAGE OverloadedStrings #-}

module App.API.Message.Handler.Get
  ( getMessages,
  )
where

import App.API.Message.API (Message)
import Control.Monad.IO.Class (liftIO)
import Database.SQLite.Simple (query_, withConnection)
import Database.SQLite.Simple.Types (Only (..))
import Servant (Handler)

getMessages :: FilePath -> Handler [Message]
getMessages dbfile = fmap (map fromOnly) . liftIO $
  withConnection dbfile $ \conn ->
    query_ conn "SELECT msg FROM messages"
