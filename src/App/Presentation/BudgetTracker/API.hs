{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.BudgetTracker.API
  ( BudgetTrackerAPI,
  )
where

import App.Presentation.BudgetTracker.Request (PostRecordRequest)
import App.Presentation.BudgetTracker.Response (RecordResponse)
import Servant

type BudgetTrackerAPI =
  AuthProtect "token-auth" :> "api" :> "records" :> Get '[JSON] [RecordResponse]
    :<|> AuthProtect "token-auth" :> "api" :> "records" :> ReqBody '[JSON] PostRecordRequest :> Post '[JSON] RecordResponse
