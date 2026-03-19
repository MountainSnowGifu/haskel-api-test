module App.Presentation.Person.Handler
  ( handlerAge,
    handlerName,
    handlerName2,
    handlerWithError,
  )
where

import App.Application.Person.UseCase (echoName, getAge, getName)
import App.Core.Env (AppMonad)
import App.Domain.Person.Entity (NameWrapper (..))
import Control.Monad.Error.Class (throwError)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (asks)
import qualified Data.ByteString.Lazy.Char8 as BSL
import Servant (err500, errBody)

-- | GET /age ハンドラ
--
--   asks :: (Config -> String) -> AppMonad String
handlerAge :: AppMonad String
handlerAge = asks getAge

-- | POST /name ハンドラ
handlerName :: NameWrapper -> AppMonad String
handlerName (NameWrapper nameIn) = return (getName nameIn)

-- | POST /name2 ハンドラ
--
--   副作用（ログ出力）は Handler 層で処理し、
--   純粋なロジックは UseCase の echoName に委譲する。
handlerName2 :: NameWrapper -> AppMonad String
handlerName2 (NameWrapper nameIn) = do
  liftIO $ print $ "input name = " ++ nameIn
  return (echoName nameIn)

-- | GET /errname ハンドラ
handlerWithError :: AppMonad String
handlerWithError =
  if True
    then throwError $ err500 {errBody = BSL.pack "Exception in module A.B.C:55.  Have a great day!"}
    else return "sras"
