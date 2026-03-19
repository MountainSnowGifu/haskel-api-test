{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Message.API
  ( MessageAPI,
  )
where

import App.Domain.Message.Entity (Message)
import Servant

type MessageAPI =
  "message" :> ReqBody '[JSON] Message :> Post '[JSON] NoContent
    :<|> "message" :> Get '[JSON] [Message]
