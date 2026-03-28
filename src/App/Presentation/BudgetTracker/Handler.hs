{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.BudgetTracker.Handler
  ( RecordRunner,
    getRecordsAllHandler,
    postRecordHandler,
    deleteRecordHandler,
    getSummaryHandler,
  )
where

import App.Application.BudgetTracker.UseCase (RecordValidationError (..), createRecord, fetchAllRecords, fetchSummary, removeRecord)
import App.Domain.Auth.Entity (User)
import App.Application.BudgetTracker.Repository (RecordRepo)
import App.Presentation.BudgetTracker.Request (PostRecordRequest, toCreateRecordCommand)
import App.Presentation.BudgetTracker.Response (DeleteRecordResponse (..), RecordResponse (..), SummaryResponse, toRecordResponse, toSummaryResponse)
import Control.Monad.IO.Class (liftIO)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Effectful (Eff, IOE)
import Servant

type RecordRunner = forall a. Eff '[RecordRepo, IOE] a -> IO a

getRecordsAllHandler :: (User -> RecordRunner) -> User -> Handler [RecordResponse]
getRecordsAllHandler mkRun user = do
  records <- liftIO $ mkRun user fetchAllRecords
  return (map toRecordResponse records)

postRecordHandler :: (User -> RecordRunner) -> User -> PostRecordRequest -> Handler RecordResponse
postRecordHandler mkRun user body = do
  result <- liftIO $ mkRun user (createRecord (toCreateRecordCommand body))
  case result of
    Left CategoryEmpty -> throwError err400
    Left AmountInvalid -> throwError err400
    Right record       -> return (toRecordResponse record)

deleteRecordHandler :: (User -> RecordRunner) -> User -> Int -> Handler DeleteRecordResponse
deleteRecordHandler mkRun user rid = do
  result <- liftIO $ mkRun user (removeRecord rid)
  case result of
    Nothing -> throwError err404
    Just () -> return $ DeleteRecordResponse "Record deleted successfully"

getSummaryHandler :: (User -> RecordRunner) -> User -> Maybe Text -> Handler SummaryResponse
getSummaryHandler mkRun user mMonth = do
  let month = fromMaybe "" mMonth
  summary <- liftIO $ mkRun user (fetchSummary month)
  return (toSummaryResponse summary)
