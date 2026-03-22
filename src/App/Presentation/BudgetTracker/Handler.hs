{-# LANGUAGE DataKinds #-}

module App.Presentation.BudgetTracker.Handler
  ( getRecordsAllHandler,
    postRecordHandler,
  )
where

import App.Application.BudgetTracker.UseCase (RecordValidationError (..), createRecord, fetchAllRecords)
import App.Domain.Auth.Entity (User)
import App.Infrastructure.DB.Types (SqliteDb)
import App.Infrastructure.Repository.RecordSQLite (runRecordRepo)
import App.Presentation.BudgetTracker.Request (PostRecordRequest, toCreateRecordCommand)
import App.Presentation.BudgetTracker.Response (RecordResponse (..), toRecordResponse)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant

getRecordsAllHandler :: SqliteDb -> User -> Handler [RecordResponse]
getRecordsAllHandler db user = do
  records <- liftIO $ runEff (runRecordRepo db user fetchAllRecords)
  return (map toRecordResponse records)

postRecordHandler :: SqliteDb -> User -> PostRecordRequest -> Handler RecordResponse
postRecordHandler db user body = do
  result <- liftIO $ runEff (runRecordRepo db user (createRecord (toCreateRecordCommand body)))
  case result of
    Left TypeEmpty -> throwError err400
    Left CategoryEmpty -> throwError err400
    Left AmountInvalid -> throwError err400
    Right record -> return (toRecordResponse record)