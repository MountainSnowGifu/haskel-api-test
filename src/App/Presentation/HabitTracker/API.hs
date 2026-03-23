{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.HabitTracker.API
  ( HabitTrackerAPI,
  )
where

import App.Presentation.HabitTracker.Response
import Servant

type HabitTrackerAPI =
  AuthProtect "token-auth" :> "api" :> "habits" :> Get '[JSON] [HabitResponse]