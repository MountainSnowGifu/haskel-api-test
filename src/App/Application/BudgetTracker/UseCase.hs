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
import App.Domain.BudgetTracker.Entity (NewRecord (..), Record, Summary (..), summarize)
import App.Domain.BudgetTracker.Repository (RecordRepo, deleteRecord, getRecordsAll, getRecordsByMonth, postRecord)
import Data.Text (Text)
import Data.Text qualified as T
import Effectful

data RecordValidationError = CategoryEmpty | AmountInvalid

toNewRecord :: CreateRecordCommand -> NewRecord
toNewRecord cmd =
  NewRecord
    { newRecordType     = cmdType cmd,
      newRecordCategory = cmdCategory cmd,
      newRecordAmount   = cmdAmount cmd,
      newRecordDate     = cmdDate cmd,
      newRecordMemo     = cmdMemo cmd
    }

validateCreate :: CreateRecordCommand -> Either RecordValidationError CreateRecordCommand
validateCreate cmd
  | T.null (cmdCategory cmd) = Left CategoryEmpty
  | cmdAmount cmd <= 0       = Left AmountInvalid
  | otherwise                = Right cmd

fetchAllRecords :: (RecordRepo :> es) => Eff es [Record]
fetchAllRecords = getRecordsAll

createRecord ::
  (RecordRepo :> es) =>
  CreateRecordCommand ->
  Eff es (Either RecordValidationError Record)
createRecord cmd = case validateCreate cmd of
  Left e      -> return (Left e)
  Right valid -> Right <$> postRecord (toNewRecord valid)

removeRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
removeRecord = deleteRecord

fetchSummary :: (RecordRepo :> es) => Text -> Eff es Summary
fetchSummary month = do
  records <- getRecordsByMonth month
  return $ summarize month records
