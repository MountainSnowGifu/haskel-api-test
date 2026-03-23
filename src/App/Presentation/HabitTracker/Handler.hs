{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.HabitTracker.Handler
  ( getHabitsAllHandler,
  )
where

import App.Application.HabitTracker.UseCase (fetchAllHabits)
import App.Domain.Auth.Entity (User)
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Repository.HabitSQLServer (runHabitRepo)
import App.Presentation.HabitTracker.Response
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant

getHabitsAllHandler :: MSSQLPool -> User -> Handler [HabitResponse]
getHabitsAllHandler db user = do
  habits <- liftIO $ runEff (runHabitRepo db user fetchAllHabits)
  return (map toHabitResponse habits)