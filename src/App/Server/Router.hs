{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module App.Server.Router
  ( runServant,
  )
where

import App.Core.Config (Config (..))
import App.Domain.Auth.Entity (User)
import App.Infrastructure.DB.Types (MSSQLPool, SqliteDb)
import App.Infrastructure.Logger.CsvLogger (csvLogger)
import App.Infrastructure.Repository.BudgetTracker.RecordSQLite (runRecordRepo)
import App.Infrastructure.Repository.Chat.ChatSTM (MessageStore, RoomState, newMessageStore, newRoomState)
import App.Infrastructure.Repository.HabitTracker.HabitSQLServer (runHabitRepo)
-- import App.Infrastructure.Repository.Task.TaskSQLServer (runTaskRepo)
import App.Infrastructure.Repository.Task.TaskSQLServer2 (runTaskRepo2)
import App.Middleware.TokenAuth (mkTokenAuthHandler)
import App.Presentation.Auth.Handler (loginHandler)
import App.Presentation.BudgetTracker.Handler (RecordRunner, deleteRecordHandler, getRecordsAllHandler, getSummaryHandler, postRecordHandler)
import App.Presentation.Chat.Handler (ConnStore, newConnStore, wsHandler)
import App.Presentation.HabitTracker.Handler (HabitRunner, deleteHabitHandler, getHabitsAllHandler, postHabitHandler)
import App.Presentation.Task.Handler (TaskRunner, deleteTaskHandler, getTaskAllHandler, getTaskHandler, patchTaskHandler, postTaskHandler, putTaskHandler)
import App.Server.API (combinedAPI)
import Database.Redis (Connection)
import Effectful (runEff)
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
  let mkTaskRunner :: User -> TaskRunner
      mkTaskRunner user eff = runEff (runTaskRepo2 sqlserverPool user eff)
      -- mkTaskRunner user eff = runEff (runTaskRepo sqlserverPool user eff)

      mkRecordRunner :: User -> RecordRunner
      mkRecordRunner user eff = runEff (runRecordRepo sqliteDb user eff)

      mkHabitRunner :: User -> HabitRunner
      mkHabitRunner user eff = runEff (runHabitRepo sqlserverPool user eff)
   in csvLogger "access.csv" $
        cors (const $ Just corsPolicy) $
          serveWithContext
            combinedAPI
            (mkTokenAuthHandler redisConn :. EmptyContext)
            ( loginHandler sqlserverPool redisConn
                :<|> (getTaskHandler mkTaskRunner :<|> getTaskAllHandler mkTaskRunner :<|> postTaskHandler mkTaskRunner :<|> putTaskHandler mkTaskRunner :<|> patchTaskHandler mkTaskRunner :<|> deleteTaskHandler mkTaskRunner)
                :<|> wsHandler rooms store connStore
                :<|> (getRecordsAllHandler mkRecordRunner :<|> postRecordHandler mkRecordRunner :<|> deleteRecordHandler mkRecordRunner :<|> getSummaryHandler mkRecordRunner)
                :<|> (getHabitsAllHandler mkHabitRunner :<|> postHabitHandler mkHabitRunner :<|> deleteHabitHandler mkHabitRunner)
            )

runServant :: Config -> SqliteDb -> MSSQLPool -> Connection -> IO ()
runServant servantConfig sqliteDb sqlserverPool redisConn = do
  rooms <- newRoomState
  store <- newMessageStore
  connStore <- newConnStore
  run (port servantConfig) (app sqliteDb sqlserverPool redisConn rooms store connStore)
