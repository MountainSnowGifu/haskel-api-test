module App.API.Person.Handler.Name2
  ( handlerName2,
  )
where

import App.API.Person.Types (NameWrapper (..))
import App.Core.Env (AppMonad)
import Control.Monad.IO.Class (liftIO)

handlerName2 :: NameWrapper -> AppMonad String
handlerName2 (NameWrapper nameIn) = do
  liftIO $ print $ "input name = " ++ nameIn
  return nameIn
