{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.HabitTracker.Handler
  ( HabitRunner,
    getHabitsAllHandler,
    postHabitHandler,
    deleteHabitHandler,
  )
where

import App.Application.HabitTracker.UseCase (HabitValidationError (..), createHabit, deleteHabit, fetchAllHabits)
import App.Domain.Auth.Entity (User)
import App.Application.HabitTracker.Repository (HabitRepo)
import App.Application.HabitTracker.Command (DeleteHabitCommand (..))
import App.Presentation.HabitTracker.Request (PostHabitRequest, toCreateHabitCommand)
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
    Left ColorEmpty -> throwError err400
    Right record -> return (toHabitResponse record)

deleteHabitHandler :: (User -> HabitRunner) -> User -> Int -> Handler NoContent
deleteHabitHandler mkRun user hid = do
  liftIO $ mkRun user (deleteHabit (DeleteHabitCommand hid))
  return NoContent