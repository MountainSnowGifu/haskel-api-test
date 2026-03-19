{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Person.API
  ( PersonAPI,
  )
where

import App.Domain.Person.Entity (NameWrapper)
import Servant

type PersonAPI =
  "age" :> Get '[PlainText] String
    :<|> "name" :> ReqBody '[JSON] NameWrapper :> Post '[PlainText] String
    :<|> "name2" :> ReqBody '[JSON] NameWrapper :> Post '[PlainText] String
    :<|> "errname" :> Get '[PlainText] String
