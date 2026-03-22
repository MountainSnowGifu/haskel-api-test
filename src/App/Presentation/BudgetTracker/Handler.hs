{-# LANGUAGE DataKinds #-}

module App.Presentation.BudgetTracker.Handler
  ( getRecordsAllHandler,
  )
where

import App.Application.BudgetTracker.UseCase (fetchAllRecords)
import App.Domain.Auth.Entity (User)
import App.Infrastructure.DB.Types (SqliteDb)
import App.Infrastructure.Repository.RecordSQLite (runRecordRepo)
import App.Presentation.BudgetTracker.Response (RecordResponse (..), toRecordResponse)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant

getRecordsAllHandler :: SqliteDb -> User -> Handler [RecordResponse]
getRecordsAllHandler db user = do
  records <- liftIO $ runEff (runRecordRepo db user fetchAllRecords)
  return (map toRecordResponse records)