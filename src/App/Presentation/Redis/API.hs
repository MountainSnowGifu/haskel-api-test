{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Redis.API
  ( RedisAPI,
  )
where

import Servant

type RedisAPI = "redisget" :> Get '[PlainText] String
