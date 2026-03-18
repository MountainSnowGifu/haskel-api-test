{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.RedisTest.API
  ( RedisTestAPI,
  )
where

import Servant

type RedisTestAPI = "redisget" :> Get '[PlainText] String