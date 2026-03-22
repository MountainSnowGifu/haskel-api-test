{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.BudgetTracker.UseCase
  ( RecordValidationError (..),
    createRecord,
    fetchAllRecords,
  )
where

import App.Application.BudgetTracker.Command (CreateRecordCommand (..))
import App.Domain.BudgetTracker.Entity (Record)
import App.Domain.BudgetTracker.Repository (RecordRepo, getRecordsAll, postRecord)
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