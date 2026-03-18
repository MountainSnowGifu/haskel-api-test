module App.Person.Handler.Name2
  ( handlerName2,
  )
where

import App.Env (AppM)
import App.Person.Types (NameWrapper (..))
import Control.Monad.IO.Class (liftIO)

handlerName2 :: NameWrapper -> AppM String
handlerName2 (NameWrapper nameIn) = do
  liftIO $ print $ "input name = " ++ nameIn
  return nameIn
