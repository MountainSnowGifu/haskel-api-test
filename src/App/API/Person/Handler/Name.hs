module App.API.Person.Handler.Name
  ( handlerName,
  )
where

import App.API.Person.Types (NameWrapper (..))
import App.Core.Env (AppM)

handlerName :: NameWrapper -> AppM String
handlerName (NameWrapper nameIn) = return ("name: " ++ nameIn)
