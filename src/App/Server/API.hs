{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Server.API
  ( API,
    combinedAPI,
  )
where

import App.Domain.Auth.Entity (Username)
import App.Presentation.Auth.API (LoginAPI)
import App.Presentation.Greeting.API (GreetingAPI)
import App.Presentation.Marketing.API (MarketingAPI)
import App.Presentation.Message.API (MessageAPI)
import App.Presentation.Person.API (PersonAPI)
import App.Presentation.Redis.API (RedisAPI)
import App.Presentation.SqlServerDemo.API (SqlServerAPI)
import App.Presentation.Task.API (TaskAPI)
import Servant
import Servant.Server.Experimental.Auth (AuthServerData)

-- | AuthProtect "token-auth" が解決する値の型を宣言する
--
-- これにより Servant は AuthHandler Request Username を
-- Context から探してハンドラに渡すことができる。
type instance AuthServerData (AuthProtect "token-auth") = Username

type API = LoginAPI :<|> MarketingAPI :<|> PersonAPI :<|> MessageAPI :<|> SqlServerAPI :<|> RedisAPI :<|> GreetingAPI :<|> TaskAPI

combinedAPI :: Proxy API
combinedAPI = Proxy
