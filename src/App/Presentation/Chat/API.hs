{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Chat.API
  ( ChatAPI,
  )
where

import Servant ((:>))
import Servant.API.WebSocket (WebSocket)

type ChatAPI =
  "chat" :> "ws" :> WebSocket
