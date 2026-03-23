{-# LANGUAGE OverloadedStrings #-}

module App.Server.Router
  ( runServant,
  )
where

import App.Core.Config (Config (..))
import App.Infrastructure.DB.Types (MSSQLPool, SqliteDb)
import App.Infrastructure.Logger.CsvLogger (csvLogger)
import App.Infrastructure.Repository.ChatSTM (MessageStore, RoomState, newMessageStore, newRoomState)
import App.Middleware.TokenAuth (mkTokenAuthHandler)
import App.Presentation.Auth.Handler (loginHandler)
import App.Presentation.BudgetTracker.Handler (deleteRecordHandler, getRecordsAllHandler, getSummaryHandler, postRecordHandler)
import App.Presentation.Chat.Handler (ConnStore, newConnStore, wsHandler)
import App.Presentation.HabitTracker.Handler (getHabitsAllHandler)
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

app :: SqliteDb -> MSSQLPool -> Connection -> RoomState -> MessageStore -> ConnStore -> Application
app sqliteDb sqlserverPool redisConn rooms store connStore =
  csvLogger "access.csv" $
    cors (const $ Just corsPolicy) $
      serveWithContext
        combinedAPI
        (mkTokenAuthHandler redisConn :. EmptyContext)
        ( loginHandler sqlserverPool redisConn
            :<|> (getTaskHandler sqlserverPool :<|> getTaskAllHandler sqlserverPool :<|> postTaskHandler sqlserverPool :<|> putTaskHandler sqlserverPool :<|> patchTaskHandler sqlserverPool :<|> deleteTaskHandler sqlserverPool)
            :<|> wsHandler rooms store connStore
            :<|> (getRecordsAllHandler sqliteDb :<|> postRecordHandler sqliteDb :<|> deleteRecordHandler sqliteDb :<|> getSummaryHandler sqliteDb)
            :<|> getHabitsAllHandler sqlserverPool
        )

runServant :: Config -> SqliteDb -> MSSQLPool -> Connection -> IO ()
runServant servantConfig sqliteDb sqlserverPool redisConn = do
  rooms <- newRoomState
  store <- newMessageStore
  connStore <- newConnStore
  run (port servantConfig) (app sqliteDb sqlserverPool redisConn rooms store connStore)
