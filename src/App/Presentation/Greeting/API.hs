{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Greeting.API
  ( GreetingAPI,
  )
where

import App.Domain.Greeting.Entity (HelloMessage, Position)
import Servant

type GreetingAPI =
  "position" :> Capture "x" Int :> Capture "y" Int :> Get '[JSON] Position
    :<|> "hello" :> QueryParam "name" String :> Get '[JSON] HelloMessage
