{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.HabitTracker.Handler
  ( HabitRunner,
    getHabitsAllHandler,
    postHabitHandler,
    deleteHabitHandler,
    getHabitHandler,
    updateHabitHandler,
  )
where

import App.Application.HabitTracker.Command (DeleteHabitCommand (..))
import App.Application.HabitTracker.Repository (HabitRepo)
import App.Application.HabitTracker.UseCase (HabitValidationError (..), createHabit, deleteHabit, fetchAllHabits, fetchHabit, updateHabit)
import App.Domain.Auth.Entity (User)
import App.Domain.HabitTracker.Entity (HabitWithStats (..))
import App.Presentation.HabitTracker.Request (PatchHabitRequest, PostHabitRequest, toCreateHabitCommand, toUpdateHabitCommand)
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

getHabitHandler :: (User -> HabitRunner) -> User -> Int -> Handler HabitResponse
getHabitHandler mkRun user hid = do
  result <- liftIO $ mkRun user (fetchHabit hid)
  case result of
    Nothing -> throwError err404
    Just habit -> return (toHabitResponse habit)

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

updateHabitHandler :: (User -> HabitRunner) -> User -> Int -> PatchHabitRequest -> Handler HabitResponse
updateHabitHandler mkRun user hid body = do
  habit <- liftIO $ mkRun user (updateHabit (toUpdateHabitCommand hid body))
  return $ toHabitResponse (HabitWithStats habit 0 0 0 False)