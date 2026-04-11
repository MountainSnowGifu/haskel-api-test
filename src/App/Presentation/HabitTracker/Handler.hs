{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.HabitTracker.Handler
  ( HabitRunner,
    getHabitsAllHandler,
    postHabitHandler,
    deleteHabitHandler,
    getHabitHandler,
    updateHabitHandler,
    createHabitLogHandler,
    getMonthlyReportHandler,
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.HabitTracker.Command (DeleteHabitCommand (..), FetchHabitLogsCommand (..))
import App.Application.HabitTracker.Repository (HabitRepo)
import App.Application.HabitTracker.UseCase
  ( HabitValidationError (..),
    createHabit,
    createHabitLog,
    deleteHabit,
    fetchAllHabits,
    fetchHabit,
    fetchHabitLogs,
    updateHabit,
  )
import App.Domain.HabitTracker.Entity (HabitWithStats (..))
import App.Presentation.HabitTracker.Request
  ( PatchHabitRequest,
    PostHabitLogRequest,
    PostHabitRequest,
    toCreateHabitCommand,
    toCreateHabitLogCommand,
    toUpdateHabitCommand,
  )
import App.Presentation.HabitTracker.Response
  ( HabitResponse,
    MonthlyReportResponse,
    toHabitResponse,
    toMonthlyReportResponse,
  )
import Control.Monad.IO.Class (liftIO)
import Effectful (Eff, IOE)
import Servant

type HabitRunner = forall a. Eff '[HabitRepo, IOE] a -> IO a

getHabitsAllHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> Handler [HabitResponse]
getHabitsAllHandler mkRun user = do
  habits <- liftIO $ mkRun user fetchAllHabits
  return (map toHabitResponse habits)

getHabitHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> Int -> Handler HabitResponse
getHabitHandler mkRun user hid = do
  result <- liftIO $ mkRun user (fetchHabit hid)
  case result of
    Nothing -> throwError err404
    Just habit -> return (toHabitResponse habit)

postHabitHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> PostHabitRequest -> Handler HabitResponse
postHabitHandler mkRun user body = do
  result <- liftIO $ mkRun user (createHabit (toCreateHabitCommand body))
  case result of
    Left CategoryEmpty -> throwError err400
    Left ColorEmpty -> throwError err400
    Right Nothing -> throwError err500
    Right (Just record) -> return (toHabitResponse record)

deleteHabitHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> Int -> Handler NoContent
deleteHabitHandler mkRun user hid = do
  deleted <- liftIO $ mkRun user (deleteHabit (DeleteHabitCommand hid))
  if deleted then return NoContent else throwError err404

updateHabitHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> Int -> PatchHabitRequest -> Handler HabitResponse
updateHabitHandler mkRun user hid body = do
  result <- liftIO $ mkRun user (updateHabit (toUpdateHabitCommand hid body))
  case result of
    Nothing -> throwError err404
    Just habit -> return $ toHabitResponse (HabitWithStats habit 0 0 0 False)

createHabitLogHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> Int -> PostHabitLogRequest -> Handler NoContent
createHabitLogHandler mkRun user hid body = do
  result <- liftIO $ mkRun user (createHabitLog (toCreateHabitLogCommand hid body))
  case result of
    Nothing -> throwError err404
    Just () -> return NoContent

getMonthlyReportHandler :: (AuthPrincipal -> HabitRunner) -> AuthPrincipal -> Int -> Int -> Handler [MonthlyReportResponse]
getMonthlyReportHandler mkRun user year month = do
  results <- liftIO $ mkRun user (fetchHabitLogs (FetchHabitLogsCommand year month))
  return (map toMonthlyReportResponse results)