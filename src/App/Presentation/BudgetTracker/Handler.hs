{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.BudgetTracker.Handler
  ( getRecordsAllHandler,
    postRecordHandler,
    deleteRecordHandler,
    getSummaryHandler,
  )
where

import App.Application.BudgetTracker.UseCase (RecordValidationError (..), createRecord, fetchAllRecords, fetchSummary, removeRecord)
import App.Domain.Auth.Entity (User)
import App.Infrastructure.DB.Types (SqliteDb)
import App.Infrastructure.Repository.RecordSQLite (runRecordRepo)
import App.Presentation.BudgetTracker.Request (PostRecordRequest, toCreateRecordCommand)
import App.Presentation.BudgetTracker.Response (DeleteRecordResponse (..), RecordResponse (..), SummaryResponse, toRecordResponse, toSummaryResponse)
import Control.Monad.IO.Class (liftIO)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
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
    Left CategoryEmpty -> throwError err400
    Left AmountInvalid -> throwError err400
    Right record -> return (toRecordResponse record)

deleteRecordHandler :: SqliteDb -> User -> Int -> Handler DeleteRecordResponse
deleteRecordHandler db user rid = do
  result <- liftIO $ runEff (runRecordRepo db user (removeRecord rid))
  case result of
    Nothing -> throwError err404
    Just () -> return $ DeleteRecordResponse "Record deleted successfully"

getSummaryHandler :: SqliteDb -> User -> Maybe Text -> Handler SummaryResponse
getSummaryHandler db user mMonth = do
  let month = fromMaybe "" mMonth
  summary <- liftIO $ runEff (runRecordRepo db user (fetchSummary month))
  return (toSummaryResponse summary)
