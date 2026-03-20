{-# LANGUAGE OverloadedStrings #-}

module App.Server.Router
  ( runServant,
  )
where

import App.Core.Config (Config (..))
import App.Core.Env (nt)
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Logger.CsvLogger (csvLogger)
import App.Infrastructure.Logger.CsvLogger2 (csvLogger2)
import App.Middleware.TokenAuth (mkTokenAuthHandler)
import App.Presentation.Auth.Handler (loginHandler)
import App.Presentation.Greeting.Handler (hello, position)
import App.Presentation.Marketing.Handler (marketing)
import App.Presentation.Message.Handler (getMessagesHandler, postMessageHandler)
import App.Presentation.Person.API (PersonAPI)
import App.Presentation.Person.Handler (handlerAge, handlerName, handlerName2, handlerWithError)
import App.Presentation.Redis.Handler (redisGet)
import App.Presentation.SqlServerDemo.Handler (getSqlserverHandler, postSqlserverHandler)
import App.Presentation.Task.Handler (getTaskAllHandler, getTaskHandler, postTaskHandler)
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
app servantConfig sqliteDbName sqlserverPool redisConn =
  csvLogger "access.csv" $
    csvLogger2 "access2.csv" $
      cors (const $ Just corsPolicy) $
        serveWithContext
          combinedAPI
          (mkTokenAuthHandler redisConn :. EmptyContext)
          ( loginHandler redisConn
              :<|> marketing
              :<|> hoistServer (Proxy :: Proxy PersonAPI) (nt servantConfig) (handlerAge :<|> handlerName :<|> handlerName2 :<|> handlerWithError)
              :<|> (postMessageHandler sqliteDbName :<|> getMessagesHandler sqliteDbName)
              :<|> (getSqlserverHandler sqlserverPool :<|> postSqlserverHandler sqlserverPool)
              :<|> redisGet redisConn
              :<|> (position :<|> hello)
              :<|> (getTaskHandler sqlserverPool :<|> getTaskAllHandler sqlserverPool :<|> postTaskHandler sqlserverPool)
          )

runServant :: Config -> String -> MSSQLPool -> Connection -> IO ()
runServant servantConfig sqliteDbName sqlserverPool redisConn = run (port servantConfig) (app servantConfig sqliteDbName sqlserverPool redisConn)
