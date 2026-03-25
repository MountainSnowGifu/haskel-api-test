{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.HabitTracker.Handler
  ( HabitRunner,
    getHabitsAllHandler,
  )
where

import App.Application.HabitTracker.UseCase (fetchAllHabits)
import App.Domain.Auth.Entity (User)
import App.Domain.HabitTracker.Repository (HabitRepo)
import App.Presentation.HabitTracker.Response
import Control.Monad.IO.Class (liftIO)
import Effectful (Eff, IOE)
import Servant

type HabitRunner = forall a. Eff '[HabitRepo, IOE] a -> IO a

getHabitsAllHandler :: (User -> HabitRunner) -> User -> Handler [HabitResponse]
getHabitsAllHandler mkRun user = do
  habits <- liftIO $ mkRun user fetchAllHabits
  return (map toHabitResponse habits)
