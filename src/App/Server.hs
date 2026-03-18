{-# LANGUAGE OverloadedStrings #-}

module App.Server
  ( runServant,
  )
where

import App.API (combinedAPI)
import App.Config (Config (..))
import App.DB (MSSQLPool)
import App.Env (nt)
import App.Greeting.Handler.Hello (hello)
import App.Greeting.Handler.Position (position)
import App.Marketing.Handler (marketing)
import App.Message.Handler.Get (getMessages)
import App.Message.Handler.Post (postMessage)
import App.Person.API (PersonAPI)
import App.Person.Handler.Age (handlerAge)
import App.Person.Handler.Name (handlerName)
import App.Person.Handler.Name2 (handlerName2)
import App.Person.Handler.WithError (handlerWithError)
import App.SqlServer.Handler.Get (getSqlserver)
import App.SqlServer.Handler.Post (postSqlserver)
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors
import Servant

corsPolicy :: CorsResourcePolicy
corsPolicy =
  simpleCorsResourcePolicy
    { corsOrigins = Nothing,
      corsMethods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      corsRequestHeaders = ["Content-Type", "Authorization"]
    }

app :: Config -> String -> MSSQLPool -> Application
app config dbname pool =
  cors (const $ Just corsPolicy) $
    serve combinedAPI $
      (position :<|> hello)
        :<|> marketing
        :<|> hoistServer (Proxy :: Proxy PersonAPI) (nt config) (handlerAge :<|> handlerName :<|> handlerName2 :<|> handlerWithError)
        :<|> (postMessage dbname :<|> getMessages dbname)
        :<|> (getSqlserver pool :<|> postSqlserver pool)

runServant :: Config -> String -> MSSQLPool -> IO ()
runServant config dbname pool = run (port config) (app config dbname pool)
