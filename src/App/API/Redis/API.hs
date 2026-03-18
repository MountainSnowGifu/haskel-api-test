{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.API.Redis.API
  ( RedisAPI,
  )
where

import Servant

type RedisAPI = "redisget" :> Get '[PlainText] String
