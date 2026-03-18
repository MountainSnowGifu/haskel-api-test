module App.Greeting.Handler.Position
  ( position,
  )
where

import App.Greeting.Types (Position (..))
import Servant (Handler)

position :: Int -> Int -> Handler Position
position x y = return (Position x y)
