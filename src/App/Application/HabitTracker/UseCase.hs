{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.HabitTracker.UseCase
  ( fetchAllHabits,
    HabitValidationError (..),
    createHabit,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..))
import App.Domain.HabitTracker.Entity (Habit, NewHabit (..))
import App.Domain.HabitTracker.Repository (HabitRepo, getHabitAll, postHabit)
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
  Right (CreateHabitCommand ht hd hc hcat) ->
    Right <$> postHabit (NewHabit ht hd hc hcat)