{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.RedisTest.API
  ( RedisTestAPI,
  )
where

import App.Auth.BasicAuth (User)
import Servant

type RedisTestAPI = BasicAuth "Web Study API" User :> "redisget" :> Get '[PlainText] String