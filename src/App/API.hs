{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.API
  ( API1,
    API2,
    API3,
    API4,
    API,
    userAPI,
    userAPI2,
    userAPI3,
    combinedAPI,
    Message,
  )
where

import App.Types
import Servant

type Message = String

type API1 =
  "position" :> Capture "x" Int :> Capture "y" Int :> Get '[JSON] Position
    :<|> "hello" :> QueryParam "name" String :> Get '[JSON] HelloMessage
    :<|> "marketing" :> ReqBody '[JSON] ClientInfo :> Post '[JSON] Email

type API2 =
  "age" :> Get '[PlainText] String
    :<|> "name" :> ReqBody '[JSON] NameWrapper :> Post '[PlainText] String
    :<|> "name2" :> ReqBody '[JSON] NameWrapper :> Post '[PlainText] String
    :<|> "errname" :> Get '[PlainText] String

type API3 =
  "message" :> ReqBody '[JSON] Message :> Post '[JSON] NoContent
    :<|> "message" :> Get '[JSON] [Message]

type API4 =
  "sqlserver" :> Get '[PlainText] String :<|> "sqlserver" :> Post '[PlainText] String

type API = API1 :<|> API2 :<|> API3 :<|> API4

userAPI :: Proxy API1
userAPI = Proxy

userAPI2 :: Proxy API2
userAPI2 = Proxy

userAPI3 :: Proxy API3
userAPI3 = Proxy

userAPI4 :: Proxy API4
userAPI4 = Proxy

combinedAPI :: Proxy API
combinedAPI = Proxy
