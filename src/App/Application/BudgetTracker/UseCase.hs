{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
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
import App.Application.BudgetTracker.Repository (RecordRepo, deleteRecord, getRecordsAll, getRecordsByMonth)
import App.Application.BudgetTracker.Repository qualified as RecordRepo
import Data.Text (Text)
import Data.Text qualified as T
import Effectful

data RecordValidationError = CategoryEmpty | AmountInvalid

validateCreate :: CreateRecordCommand -> Either RecordValidationError CreateRecordCommand
validateCreate cmd
  | T.null (cmdRecordCategory cmd) = Left CategoryEmpty
  | cmdRecordAmount cmd <= 0 = Left AmountInvalid
  | otherwise = Right cmd

fetchAllRecords :: (RecordRepo :> es) => Eff es [Record]
fetchAllRecords = getRecordsAll

createRecord ::
  (RecordRepo :> es) =>
  CreateRecordCommand ->
  Eff es (Either RecordValidationError Record)
createRecord cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right cmd' ->
    Right <$> RecordRepo.createRecord cmd'

removeRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
removeRecord = deleteRecord

fetchSummary :: (RecordRepo :> es) => Text -> Eff es Summary
fetchSummary month = do
  records <- getRecordsByMonth month
  return $ summarize month records
