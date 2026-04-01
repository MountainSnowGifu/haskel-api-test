{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.HabitTracker.API
  ( HabitTrackerAPI,
  )
where

import App.Presentation.HabitTracker.Request
import App.Presentation.HabitTracker.Response
import Servant

type HabitTrackerAPI =
  AuthProtect "token-auth" :> "api" :> "habits" :> Get '[JSON] [HabitResponse]
    :<|> AuthProtect "token-auth" :> "api" :> "habits" :> ReqBody '[JSON] PostHabitRequest :> Post '[JSON] HabitResponse
    :<|> AuthProtect "token-auth" :> "api" :> "habits" :> Capture "id" Int :> Delete '[JSON] NoContent
    :<|> AuthProtect "token-auth" :> "api" :> "habits" :> Capture "id" Int :> Get '[JSON] HabitResponse
    :<|> AuthProtect "token-auth" :> "api" :> "habits" :> Capture "id" Int :> ReqBody '[JSON] PatchHabitRequest :> Patch '[JSON] HabitResponse
    :<|> AuthProtect "token-auth" :> "api" :> "habits" :> Capture "habitId" Int :> "logs" :> ReqBody '[JSON] PostHabitLogRequest :> Post '[JSON] NoContent
    :<|> AuthProtect "token-auth" :> "api" :> "reports" :> "monthly" :> QueryParam' '[Required] "year" Int :> QueryParam' '[Required] "month" Int :> Get '[JSON] [MonthlyReportResponse]
