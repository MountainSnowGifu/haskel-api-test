{-# LANGUAGE OverloadedStrings #-}

module App.Server.Router
  ( runServant,
  )
where

import App.API.Greeting.Handler.Hello (hello)
import App.API.Greeting.Handler.Position (position)
import App.API.Marketing.Handler (marketing)
import App.API.Message.Handler.Get (getMessages)
import App.API.Message.Handler.Post (postMessage)
import App.API.Person.API (PersonAPI)
import App.API.Person.Handler.Age (handlerAge)
import App.API.Person.Handler.Name (handlerName)
import App.API.Person.Handler.Name2 (handlerName2)
import App.API.Person.Handler.WithError (handlerWithError)
import App.API.Redis.Handler.Get (redisGet)
import App.API.SqlServerDemo.Handler.Get (getSqlserver)
import App.API.SqlServerDemo.Handler.Post (postSqlserver)
import App.Auth.Handler (loginHandler)
import App.Core.Config (Config (..))
import App.Core.Env (nt)
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Logger.CsvLogger (csvLogger)
import App.Infrastructure.Logger.CsvLogger2 (csvLogger2)
import App.Middleware.TokenAuth (tokenAuth)
import App.Server.API (combinedAPI)
import Database.Redis (Connection)
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

app :: Config -> String -> MSSQLPool -> Connection -> Application
app config sqliteDbName sqlserverPool redisConn =
  csvLogger "access.csv" $
    csvLogger2 "access2.csv" $
      tokenAuth redisConn $
        cors (const $ Just corsPolicy) $
          serve
            combinedAPI
            ( (position :<|> hello)
                :<|> marketing
                :<|> hoistServer (Proxy :: Proxy PersonAPI) (nt config) (handlerAge :<|> handlerName :<|> handlerName2 :<|> handlerWithError)
                :<|> (postMessage sqliteDbName :<|> getMessages sqliteDbName)
                :<|> (getSqlserver sqlserverPool :<|> postSqlserver sqlserverPool)
                :<|> redisGet redisConn
                :<|> loginHandler redisConn
            )

runServant :: Config -> String -> MSSQLPool -> Connection -> IO ()
runServant config sqliteDbName sqlserverPool redisConn = run (port config) (app config sqliteDbName sqlserverPool redisConn)