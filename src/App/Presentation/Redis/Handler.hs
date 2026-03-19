{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Redis.Handler
  ( redisGet,
  )
where

import App.Application.Redis.UseCase (getValue)
import App.Infrastructure.Repository.RedisValue (runRedisRepo)
import Control.Monad.IO.Class (liftIO)
import Database.Redis (Connection)
import Effectful (runEff)
import Servant

-- | GET /redisget ハンドラ
--
--   型の流れ:
--     Eff '[RedisRepo, IOE] (Maybe ByteString)
--       → (runRedisRepo) → Eff '[IOE] (Maybe ByteString)
--       → (runEff)       → IO (Maybe ByteString)
--       → (liftIO)       → Handler (Maybe ByteString)
--       → case で String に変換
redisGet :: Connection -> Handler String
redisGet conn = do
  mval <- liftIO $ runEff $ runRedisRepo conn $ getValue "hello"
  case mval of
    Just val -> return $ show val
    Nothing -> return "key not found"
