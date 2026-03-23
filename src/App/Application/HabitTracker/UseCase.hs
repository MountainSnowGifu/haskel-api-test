{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.HabitTracker.UseCase
  ( fetchAllHabits,
  )
where

import App.Domain.HabitTracker.Entity (Habit)
import App.Domain.HabitTracker.Repository (HabitRepo, getHabitAll)
import Effectful (Eff, (:>))

fetchAllHabits :: (HabitRepo :> es) => Eff es [Habit]
fetchAllHabits = getHabitAll