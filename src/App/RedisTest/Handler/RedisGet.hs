{-# LANGUAGE OverloadedStrings #-}

module App.RedisTest.Handler.RedisGet
  ( redisGet,
  )
where

import App.Auth.BasicAuth (User)
import App.DB.RedisPool (withRedisConn)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString.Lazy.Char8 as BL
import Database.Redis (Connection, get)
import Servant

redisGet :: Connection -> User -> Handler String
redisGet conn _user = do
  result <- liftIO $ withRedisConn conn $ get "hello"
  case result of
    Right (Just val) -> return $ show val
    Right Nothing -> return "key not found"
    Left err -> throwError $ err500 {errBody = BL.pack (show err)}
