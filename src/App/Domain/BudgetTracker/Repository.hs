{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.BudgetTracker.Repository
  ( RecordRepo (..),
    getRecordsAll,
    postRecord,
  )
where

import App.Application.BudgetTracker.Command (CreateRecordCommand)
import App.Domain.BudgetTracker.Entity (Record (..))
import Effectful
import Effectful.Dispatch.Dynamic (send)

data RecordRepo :: Effect where
  GetRecordsAll :: RecordRepo m [Record]
  PostRecord :: CreateRecordCommand -> RecordRepo m Record

type instance DispatchOf RecordRepo = Dynamic

getRecordsAll :: (RecordRepo :> es) => Eff es [Record]
getRecordsAll = send GetRecordsAll

postRecord :: (RecordRepo :> es) => CreateRecordCommand -> Eff es Record
postRecord cmd = send (PostRecord cmd)