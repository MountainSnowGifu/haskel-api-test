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
import App.Domain.BudgetTracker.Operation (CreateRecord (..))
import App.Domain.BudgetTracker.Repository (RecordRepo, deleteRecord, getRecordsAll, getRecordsByMonth)
import App.Domain.BudgetTracker.Repository qualified as RecordRepo
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
  Right (CreateRecordCommand rt rc ra rd rm _ _) ->
    Right <$> RecordRepo.createRecord (CreateRecord rt rc ra rd rm)

removeRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
removeRecord = deleteRecord

fetchSummary :: (RecordRepo :> es) => Text -> Eff es Summary
fetchSummary month = do
  records <- getRecordsByMonth month
  return $ summarize month records
