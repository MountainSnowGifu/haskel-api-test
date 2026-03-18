module App.API.Person.Handler.Age
  ( handlerAge,
  )
where

import App.Core.Config (Config (..))
import App.Core.Env (AppMonad)
import Control.Monad.Reader (ask)

handlerAge :: AppMonad String
handlerAge = do
  cfg <- ask
  return (host cfg ++ ":" ++ show (port cfg) ++ ":31")
