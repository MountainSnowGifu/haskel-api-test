{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module App.Server.Router
  ( runServant,
  )
where

import App.Application.Auth.Principal (AuthPrincipal (..))
import App.Core.Config (Config (..), LogFormat (..))
import App.Infrastructure.DB.Types (MSSQLPool, SqliteDb)
import App.Infrastructure.Logger.CsvLogger (csvLogger)
import App.Infrastructure.Logger.JsonLogger (jsonLogger)
-- import App.Infrastructure.Repository.Task.TaskSQLServer (runTaskRepo)

import App.Infrastructure.Repository.Board.BoardSQLServer (runBoardRepo, runPublicBoardRepo)
import App.Infrastructure.Repository.BudgetTracker.RecordSQLite (runRecordRepo)
import App.Infrastructure.Repository.Chat.ChatSTM (MessageStore, RoomState, newMessageStore, newRoomState)
import App.Infrastructure.Repository.HabitTracker.HabitSQLServer (runHabitRepo)
import App.Infrastructure.Repository.Task.TaskSQLServer2 (runTaskRepo2)
import App.Middleware.TokenAuth (mkTokenAuthHandler)
import App.Presentation.Auth.Handler (loginHandler, logoutHandler)
import App.Presentation.Board.Handler
  ( BoardRunner,
    deleteBoardHandler,
    getBoardHandler,
    getBoardsHandler,
    postBoardHandler,
    updateBoardHandler,
  )
import App.Presentation.BudgetTracker.Handler
  ( RecordRunner,
    deleteRecordHandler,
    getRecordsAllHandler,
    getSummaryHandler,
    postRecordHandler,
  )
import App.Presentation.Chat.Handler (ConnStore, newConnStore, wsHandler)
import App.Presentation.HabitTracker.Handler
  ( HabitRunner,
    createHabitLogHandler,
    deleteHabitHandler,
    getHabitHandler,
    getHabitsAllHandler,
    getMonthlyReportHandler,
    postHabitHandler,
    updateHabitHandler,
  )
import App.Presentation.Task.Handler
  ( TaskRunner,
    deleteTaskHandler,
    getTaskAllHandler,
    getTaskHandler,
    patchTaskHandler,
    postTaskHandler,
    putTaskHandler,
  )
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
  let mkTaskRunner :: AuthPrincipal -> TaskRunner
      mkTaskRunner principal eff = runEff (runTaskRepo2 sqlserverPool (principalUserId principal) eff)
      -- mkTaskRunner principal eff = runEff (runTaskRepo sqlserverPool (principalUserId principal) eff)

      mkRecordRunner :: AuthPrincipal -> RecordRunner
      mkRecordRunner principal eff = runEff (runRecordRepo sqliteDb (principalUserId principal) eff)

      mkHabitRunner :: AuthPrincipal -> HabitRunner
      mkHabitRunner principal eff = runEff (runHabitRepo sqlserverPool (principalUserId principal) eff)

      boardRunner :: AuthPrincipal -> BoardRunner
      boardRunner principal eff = runEff (runBoardRepo sqlserverPool (principalUserId principal) eff)

      publicBoardRunner :: BoardRunner
      publicBoardRunner eff = runEff (runPublicBoardRepo sqlserverPool eff)

      taskHandlers =
        getTaskHandler mkTaskRunner
          :<|> getTaskAllHandler mkTaskRunner
          :<|> postTaskHandler mkTaskRunner
          :<|> putTaskHandler mkTaskRunner
          :<|> patchTaskHandler mkTaskRunner
          :<|> deleteTaskHandler mkTaskRunner

      recordHandlers =
        getRecordsAllHandler mkRecordRunner
          :<|> postRecordHandler mkRecordRunner
          :<|> deleteRecordHandler mkRecordRunner
          :<|> getSummaryHandler mkRecordRunner

      habitHandlers =
        getHabitsAllHandler mkHabitRunner
          :<|> postHabitHandler mkHabitRunner
          :<|> deleteHabitHandler mkHabitRunner
          :<|> getHabitHandler mkHabitRunner
          :<|> updateHabitHandler mkHabitRunner
          :<|> createHabitLogHandler mkHabitRunner
          :<|> getMonthlyReportHandler mkHabitRunner

      boardHandlers =
        postBoardHandler boardRunner
          :<|> getBoardsHandler publicBoardRunner
          :<|> deleteBoardHandler boardRunner
          :<|> getBoardHandler publicBoardRunner
          :<|> updateBoardHandler boardRunner
      authHandlers =
        loginHandler sqlserverPool redisConn
          :<|> logoutHandler redisConn
   in cors (const $ Just corsPolicy) $
        serveWithContext
          combinedAPI
          (mkTokenAuthHandler redisConn :. EmptyContext)
          ( authHandlers
              :<|> taskHandlers
              :<|> wsHandler rooms store connStore
              :<|> recordHandlers
              :<|> habitHandlers
              :<|> boardHandlers
          )

runServant :: Config -> SqliteDb -> MSSQLPool -> Connection -> IO ()
runServant servantConfig sqliteDb sqlserverPool redisConn = do
  rooms <- newRoomState
  store <- newMessageStore
  connStore <- newConnStore
  let logMiddleware =
        case logFormat servantConfig of
          Csv -> csvLogger (logFilePath servantConfig)
          Json -> jsonLogger (logFilePath servantConfig) (logLevel servantConfig)
      appWithMiddleware = logMiddleware (app sqliteDb sqlserverPool redisConn rooms store connStore)
  run (port servantConfig) appWithMiddleware
