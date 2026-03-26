{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.HabitTracker.Repository
  ( HabitRepo (..),
    getHabitAll,
    createHabit,
  )
where

import App.Domain.HabitTracker.Entity (Habit)
import App.Domain.HabitTracker.Operation (CreateHabit)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data HabitRepo :: Effect where
  GetHabitAll :: HabitRepo m [Habit]
  CreateHabitOp :: CreateHabit -> HabitRepo m Habit

type instance DispatchOf HabitRepo = Dynamic

getHabitAll :: (HabitRepo :> es) => Eff es [Habit]
getHabitAll = send GetHabitAll

createHabit :: (HabitRepo :> es) => CreateHabit -> Eff es Habit
createHabit op = send (CreateHabitOp op)
