{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.API.Person.API
  ( PersonAPI,
  )
where

import App.API.Person.Types (NameWrapper)
import Servant

type PersonAPI =
  "age" :> Get '[PlainText] String
    :<|> "name" :> ReqBody '[JSON] NameWrapper :> Post '[PlainText] String
    :<|> "name2" :> ReqBody '[JSON] NameWrapper :> Post '[PlainText] String
    :<|> "errname" :> Get '[PlainText] String
