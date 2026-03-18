{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.API
  ( API,
    combinedAPI,
  )
where

import App.Greeting.API (GreetingAPI)
import App.Marketing.API (MarketingAPI)
import App.Message.API (MessageAPI)
import App.Person.API (PersonAPI)
import App.SqlServer.API (SqlServerAPI)
import Servant

type API = GreetingAPI :<|> MarketingAPI :<|> PersonAPI :<|> MessageAPI :<|> SqlServerAPI

combinedAPI :: Proxy API
combinedAPI = Proxy
