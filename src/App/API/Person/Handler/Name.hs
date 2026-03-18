module App.API.Person.Handler.Name
  ( handlerName,
  )
where

import App.API.Person.Types (NameWrapper (..))
import App.Core.Env (AppMonad)

handlerName :: NameWrapper -> AppMonad String
handlerName (NameWrapper nameIn) = return ("name: " ++ nameIn)
