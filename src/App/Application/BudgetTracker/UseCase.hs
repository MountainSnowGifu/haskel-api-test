{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.BudgetTracker.UseCase
  ( RecordValidationError (..),
    createRecord,
    fetchAllRecords,
    fetchSummary,
    removeRecord,
  )
where

import App.Application.BudgetTracker.Command (CreateRecordCommand (..))
import App.Domain.BudgetTracker.Entity (Record, Summary (..), summarize)
import App.Domain.BudgetTracker.Repository (RecordRepo, deleteRecord, getRecordsAll, getRecordsByMonth, postRecord)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime)
import Effectful

data RecordValidationError = TypeEmpty | CategoryEmpty | AmountInvalid

validateCreate :: CreateRecordCommand -> Either RecordValidationError CreateRecordCommand
validateCreate cmd
  | T.null (cmdType cmd) = Left TypeEmpty
  | T.null (cmdCategory cmd) = Left CategoryEmpty
  | cmdAmount cmd <= 0 = Left AmountInvalid
  | otherwise = Right cmd

fetchAllRecords :: (RecordRepo :> es) => Eff es [Record]
fetchAllRecords = getRecordsAll

createRecord ::
  (RecordRepo :> es, IOE :> es) =>
  CreateRecordCommand ->
  Eff es (Either RecordValidationError Record)
createRecord cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right valid -> do
    now <- liftIO $ T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" <$> getCurrentTime
    Right <$> postRecord valid {cmdCreatedAt = now, cmdUpdatedAt = now}

removeRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
removeRecord = deleteRecord

fetchSummary :: (RecordRepo :> es) => Text -> Eff es Summary
fetchSummary month = do
  records <- getRecordsByMonth month
  return $ summarize month records