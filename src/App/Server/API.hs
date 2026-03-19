{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Server.API
  ( API,
    combinedAPI,
  )
where

import App.Presentation.Auth.API (LoginAPI)
import App.Presentation.Greeting.API (GreetingAPI)
import App.Presentation.Marketing.API (MarketingAPI)
import App.Presentation.Message.API (MessageAPI)
import App.Presentation.Person.API (PersonAPI)
import App.Presentation.Redis.API (RedisAPI)
import App.Presentation.SqlServerDemo.API (SqlServerAPI)
import Servant

type API = GreetingAPI :<|> MarketingAPI :<|> PersonAPI :<|> MessageAPI :<|> SqlServerAPI :<|> RedisAPI :<|> LoginAPI

combinedAPI :: Proxy API
combinedAPI = Proxy
