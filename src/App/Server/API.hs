{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Server.API
  ( API,
    combinedAPI,
  )
where

import App.API.Greeting.API (GreetingAPI)
import App.API.Marketing.API (MarketingAPI)
import App.API.Message.API (MessageAPI)
import App.API.Person.API (PersonAPI)
import App.API.Redis.API (RedisAPI)
import App.API.SqlServerDemo.API (SqlServerAPI)
import App.Auth.Handler (LoginAPI)
import Servant

type API = GreetingAPI :<|> MarketingAPI :<|> PersonAPI :<|> MessageAPI :<|> SqlServerAPI :<|> RedisAPI :<|> LoginAPI

combinedAPI :: Proxy API
combinedAPI = Proxy
