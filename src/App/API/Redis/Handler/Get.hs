{-# LANGUAGE OverloadedStrings #-}

module App.API.Redis.Handler.Get
  ( redisGet,
  )
where

import App.Infrastructure.DB.Redis (withRedisConn)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString.Lazy.Char8 as BL
import Database.Redis (Connection, get)
import Servant

redisGet :: Connection -> Handler String
redisGet conn = do
  result <- liftIO $ withRedisConn conn $ get "hello"
  case result of
    Right (Just val) -> return $ show val
    Right Nothing -> return "key not found"
    Left err -> throwError $ err500 {errBody = BL.pack (show err)}
