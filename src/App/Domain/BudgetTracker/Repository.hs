{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.BudgetTracker.Repository
  ( RecordRepo (..),
    getRecordsAll,
    postRecord,
    deleteRecord,
    getRecordsByMonth,
  )
where

import App.Domain.BudgetTracker.Entity (NewRecord (..), Record (..))
import Data.Text (Text)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data RecordRepo :: Effect where
  GetRecordsAll :: RecordRepo m [Record]
  PostRecord :: NewRecord -> RecordRepo m Record
  DeleteRecord :: Int -> RecordRepo m (Maybe ())
  GetRecordsByMonth :: Text -> RecordRepo m [Record]

type instance DispatchOf RecordRepo = Dynamic

getRecordsAll :: (RecordRepo :> es) => Eff es [Record]
getRecordsAll = send GetRecordsAll

postRecord :: (RecordRepo :> es) => NewRecord -> Eff es Record
postRecord cmd = send (PostRecord cmd)

deleteRecord :: (RecordRepo :> es) => Int -> Eff es (Maybe ())
deleteRecord rid = send (DeleteRecord rid)

getRecordsByMonth :: (RecordRepo :> es) => Text -> Eff es [Record]
getRecordsByMonth month = send (GetRecordsByMonth month)
