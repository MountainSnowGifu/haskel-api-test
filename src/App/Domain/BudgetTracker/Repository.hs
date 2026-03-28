{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.BudgetTracker.Repository
  ( RecordRepo (..),
    getRecordsAll,
    createRecord,
    deleteRecord,
    getRecordsByMonth,
  )
where

import App.Application.BudgetTracker.Command (CreateRecordCmd)
import App.Domain.BudgetTracker.Entity (Record (..))
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data RecordRepo :: Effect where
  GetRecordsOp :: RecordRepo m [Record]
  CreateRecordOp :: CreateRecordCmd -> RecordRepo m Record
  DeleteRecordOp :: Int -> RecordRepo m (Maybe ())
  GetRecordsByMonthOp :: Text -> RecordRepo m [Record]

type instance DispatchOf RecordRepo = Dynamic

getRecordsAll :: (RecordRepo :> es) => Eff es [Record]
getRecordsAll = send GetRecordsOp

createRecord :: (RecordRepo :> es) => CreateRecordCmd -> Eff es Record
createRecord op = send (CreateRecordOp op)

deleteRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
deleteRecord rid = send (DeleteRecordOp rid)

getRecordsByMonth :: (RecordRepo :> es) => Text -> Eff es [Record]
getRecordsByMonth month = send (GetRecordsByMonthOp month)
