module App.Person.Handler.WithError
  ( handlerWithError,
  )
where

import App.Env (AppM)
import Control.Monad.Error.Class (throwError)
import qualified Data.ByteString.Lazy.Char8 as BSL
import Servant (err500, errBody)

handlerWithError :: AppM String
handlerWithError =
  if True
    then throwError $ err500 {errBody = BSL.pack "Exception in module A.B.C:55.  Have a great day!"}
    else return "sras"
