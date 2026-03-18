{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Message.API
  ( MessageAPI,
    Message,
  )
where

import Servant

type Message = String

type MessageAPI =
  "message" :> ReqBody '[JSON] Message :> Post '[JSON] NoContent
    :<|> "message" :> Get '[JSON] [Message]
