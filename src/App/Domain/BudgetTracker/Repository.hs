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

import App.Domain.BudgetTracker.Entity (Record (..))
import App.Domain.BudgetTracker.Operation (CreateRecord)
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data RecordRepo :: Effect where
  GetRecordsAll :: RecordRepo m [Record]
  CreateRecordOp :: CreateRecord -> RecordRepo m Record
  DeleteRecord :: Int -> RecordRepo m (Maybe ())
  GetRecordsByMonth :: Text -> RecordRepo m [Record]

type instance DispatchOf RecordRepo = Dynamic

getRecordsAll :: (RecordRepo :> es) => Eff es [Record]
getRecordsAll = send GetRecordsAll

createRecord :: (RecordRepo :> es) => CreateRecord -> Eff es Record
createRecord op = send (CreateRecordOp op)

deleteRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
deleteRecord rid = send (DeleteRecord rid)

getRecordsByMonth :: (RecordRepo :> es) => Text -> Eff es [Record]
getRecordsByMonth month = send (GetRecordsByMonth month)
