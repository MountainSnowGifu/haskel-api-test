{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.BudgetTracker.API
  ( BudgetTrackerAPI,
  )
where

import App.Presentation.BudgetTracker.Request (PostRecordRequest)
import App.Presentation.BudgetTracker.Response (DeleteRecordResponse, RecordResponse, SummaryResponse)
import Data.Text (Text)
import Servant

type BudgetTrackerAPI =
  AuthProtect "token-auth" :> "api" :> "records" :> Get '[JSON] [RecordResponse]
    :<|> AuthProtect "token-auth" :> "api" :> "records" :> ReqBody '[JSON] PostRecordRequest :> Post '[JSON] RecordResponse
    :<|> AuthProtect "token-auth" :> "api" :> "records" :> Capture "id" Int :> Delete '[JSON] DeleteRecordResponse
    :<|> AuthProtect "token-auth" :> "api" :> "summary" :> QueryParam "month" Text :> Get '[JSON] SummaryResponse
