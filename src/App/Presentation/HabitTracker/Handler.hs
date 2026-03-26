{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.HabitTracker.Handler
  ( HabitRunner,
    getHabitsAllHandler,
    postHabitHandler,
  )
where

import App.Application.HabitTracker.UseCase (HabitValidationError (..), createHabit, fetchAllHabits)
import App.Domain.Auth.Entity (User)
import App.Domain.HabitTracker.Repository (HabitRepo)
import App.Presentation.HabitTracker.Request
import App.Presentation.HabitTracker.Response
  ( HabitResponse,
    toHabitResponse,
  )
import Control.Monad.IO.Class (liftIO)
import Effectful (Eff, IOE)
import Servant

type HabitRunner = forall a. Eff '[HabitRepo, IOE] a -> IO a

getHabitsAllHandler :: (User -> HabitRunner) -> User -> Handler [HabitResponse]
getHabitsAllHandler mkRun user = do
  habits <- liftIO $ mkRun user fetchAllHabits
  return (map toHabitResponse habits)

postHabitHandler :: (User -> HabitRunner) -> User -> PostHabitRequest -> Handler HabitResponse
postHabitHandler mkRun user body = do
  result <- liftIO $ mkRun user (createHabit (toCreateHabitCommand body))
  case result of
    Left CategoryEmpty -> throwError err400
    Left AmountInvalid -> throwError err400
    Right record -> return (toHabitResponse record)