{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.HabitTracker.UseCase
  ( fetchAllHabits,
    HabitValidationError (..),
    createHabit,
    deleteHabit,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..), DeleteHabitCommand (..))
import App.Application.HabitTracker.Repository (HabitRepo, getHabitAll)
import App.Application.HabitTracker.Repository qualified as HabitRepo
import App.Domain.HabitTracker.Entity (Habit)
import Data.Text qualified as T
import Effectful (Eff, (:>))

data HabitValidationError = CategoryEmpty | AmountInvalid

fetchAllHabits :: (HabitRepo :> es) => Eff es [Habit]
fetchAllHabits = getHabitAll

validateCreate :: CreateHabitCommand -> Either HabitValidationError CreateHabitCommand
validateCreate cmd
  | T.null (cmdHabitCategory cmd) = Left CategoryEmpty
  | T.null (cmdHabitColor cmd) = Left AmountInvalid
  | otherwise = Right cmd

createHabit ::
  (HabitRepo :> es) =>
  CreateHabitCommand ->
  Eff es (Either HabitValidationError Habit)
createHabit cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right cmd' ->
    Right <$> HabitRepo.createHabit cmd'

deleteHabit :: (HabitRepo :> es) => DeleteHabitCommand -> Eff es ()
deleteHabit (DeleteHabitCommand habitId) = HabitRepo.deleteHabit habitId
