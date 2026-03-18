module App.API.Greeting.Handler.Position
  ( position,
  )
where

import App.API.Greeting.Types (Position (..))
import Servant (Handler)

position :: Int -> Int -> Handler Position
position x y = return (Position x y)
