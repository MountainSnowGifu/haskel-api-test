{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.API
  ( API,
    combinedAPI,
  )
where

import App.Auth.Auth (LoginAPI)
import App.Greeting.API (GreetingAPI)
import App.Marketing.API (MarketingAPI)
import App.Message.API (MessageAPI)
import App.Person.API (PersonAPI)
import App.RedisTest.API (RedisTestAPI)
import App.SqlServer.API (SqlServerAPI)
import Servant

type API = GreetingAPI :<|> MarketingAPI :<|> PersonAPI :<|> MessageAPI :<|> SqlServerAPI :<|> RedisTestAPI :<|> LoginAPI

combinedAPI :: Proxy API
combinedAPI = Proxy
