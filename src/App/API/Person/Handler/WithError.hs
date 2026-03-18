module App.API.Person.Handler.WithError
  ( handlerWithError,
  )
where

import App.Core.Env (AppMonad)
import Control.Monad.Error.Class (throwError)
import qualified Data.ByteString.Lazy.Char8 as BSL
import Servant (err500, errBody)

handlerWithError :: AppMonad String
handlerWithError =
  if True
    then throwError $ err500 {errBody = BSL.pack "Exception in module A.B.C:55.  Have a great day!"}
    else return "sras"
