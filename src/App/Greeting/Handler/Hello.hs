module App.Greeting.Handler.Hello
  ( hello,
  )
where

import App.Greeting.Types (HelloMessage (..))
import Servant (Handler)

hello :: Maybe String -> Handler HelloMessage
hello mname = return . HelloMessage $ case mname of
  Nothing -> "Hello, anonymous coward"
  Just n -> "Hello, " ++ n
