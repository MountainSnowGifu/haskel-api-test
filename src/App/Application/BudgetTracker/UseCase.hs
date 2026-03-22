{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.BudgetTracker.UseCase
  ( fetchAllRecords,
  )
where

import App.Domain.BudgetTracker.Entity (Record)
import App.Domain.BudgetTracker.Repository (RecordRepo (..), getRecordsAll)
import Effectful

fetchAllRecords :: (RecordRepo :> es) => Eff es [Record]
fetchAllRecords = getRecordsAll