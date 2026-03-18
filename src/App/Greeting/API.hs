{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Greeting.API
  ( GreetingAPI,
  )
where

import App.Greeting.Types (HelloMessage, Position)
import Servant

type GreetingAPI =
  "position" :> Capture "x" Int :> Capture "y" Int :> Get '[JSON] Position
    :<|> "hello" :> QueryParam "name" String :> Get '[JSON] HelloMessage
