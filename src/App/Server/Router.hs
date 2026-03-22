{-# LANGUAGE OverloadedStrings #-}

module App.Server.Router
  ( runServant,
  )
where

import App.Core.Config (Config (..))
import App.Domain.Chat.Entity (MessageStore, RoomState, newMessageStore, newRoomState)
import App.Infrastructure.DB.Types (MSSQLPool, SqliteDb)
import App.Infrastructure.Logger.CsvLogger (csvLogger)
import App.Infrastructure.Logger.CsvLogger2 (csvLogger2)
import App.Middleware.TokenAuth (mkTokenAuthHandler)
import App.Presentation.Auth.Handler (loginHandler)
import App.Presentation.Chat.Handler (wsHandler)
import App.Presentation.Task.Handler (deleteTaskHandler, getTaskAllHandler, getTaskHandler, patchTaskHandler, postTaskHandler, putTaskHandler)
import App.Server.API (combinedAPI)
import Database.Redis (Connection)
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors
import Servant

corsPolicy :: CorsResourcePolicy
corsPolicy =
  simpleCorsResourcePolicy
    { corsOrigins = Nothing,
      corsMethods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      corsRequestHeaders = ["Content-Type", "Authorization"]
    }

app :: Config -> SqliteDb -> MSSQLPool -> Connection -> RoomState -> MessageStore -> Application
app _ _ sqlserverPool redisConn rooms store =
  csvLogger "access.csv" $
    csvLogger2 "access2.csv" $
      cors (const $ Just corsPolicy) $
        serveWithContext
          combinedAPI
          (mkTokenAuthHandler redisConn :. EmptyContext)
          ( loginHandler sqlserverPool redisConn
              :<|> (getTaskHandler sqlserverPool :<|> getTaskAllHandler sqlserverPool :<|> postTaskHandler sqlserverPool :<|> putTaskHandler sqlserverPool :<|> patchTaskHandler sqlserverPool :<|> deleteTaskHandler sqlserverPool)
              :<|> wsHandler rooms store
          )

runServant :: Config -> SqliteDb -> MSSQLPool -> Connection -> IO ()
runServant servantConfig sqliteDbName sqlserverPool redisConn = do
  rooms <- newRoomState
  store <- newMessageStore
  run (port servantConfig) (app servantConfig sqliteDbName sqlserverPool redisConn rooms store)
