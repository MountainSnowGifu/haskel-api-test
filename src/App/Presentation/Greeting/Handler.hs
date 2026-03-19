module App.Presentation.Greeting.Handler
  ( hello,
    position,
  )
where

import App.Application.Greeting.UseCase (getPosition, greetHello)
import App.Domain.Greeting.Entity (HelloMessage, Position)
import Servant (Handler)

-- | GET /hello ハンドラ
hello :: Maybe String -> Handler HelloMessage
hello = return . greetHello

-- | GET /position ハンドラ
position :: Int -> Int -> Handler Position
position x y = return $ getPosition x y
