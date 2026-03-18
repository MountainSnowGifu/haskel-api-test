module App.Person.Handler.Age
  ( handlerAge,
  )
where

import App.Config (Config (..))
import App.Env (AppM)
import Control.Monad.Reader (ask)

handlerAge :: AppM String
handlerAge = do
  cfg <- ask
  return (host cfg ++ ":" ++ show (port cfg) ++ ":31")
