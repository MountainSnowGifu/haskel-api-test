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
import App.Middleware.CsvLogger (csvLogger)
import App.Middleware.CsvLogger2 (csvLogger2)
import App.Person.API (PersonAPI)
import App.Person.Handler.Age (handlerAge)
import App.Person.Handler.Name (handlerName)
import App.Person.Handler.Name2 (handlerName2)
import App.Person.Handler.WithError (handlerWithError)
import App.RedisTest.Handler.RedisGet (redisGet)
import App.SqlServer.Handler.Get (getSqlserver)
import App.SqlServer.Handler.Post (postSqlserver)
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
      cors (const $ Just corsPolicy) $
        serve combinedAPI $
          (position :<|> hello)
            :<|> marketing
            :<|> hoistServer (Proxy :: Proxy PersonAPI) (nt config) (handlerAge :<|> handlerName :<|> handlerName2 :<|> handlerWithError)
            :<|> (postMessage sqliteDbName :<|> getMessages sqliteDbName)
            :<|> (getSqlserver sqlserverPool :<|> postSqlserver sqlserverPool)
            :<|> redisGet redisConn

runServant :: Config -> String -> MSSQLPool -> Connection -> IO ()
runServant config sqliteDbName sqlserverPool redisConn = run (port config) (app config sqliteDbName sqlserverPool redisConn)
