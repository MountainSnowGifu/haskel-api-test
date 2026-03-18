module App.Person.Handler.Name
  ( handlerName,
  )
where

import App.Env (AppM)
import App.Person.Types (NameWrapper (..))

handlerName :: NameWrapper -> AppM String
handlerName (NameWrapper nameIn) = return ("name: " ++ nameIn)
