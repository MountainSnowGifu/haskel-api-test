{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.HabitTracker.Repository
  ( HabitRepo (..),
    getHabitAll,
    createHabit,
    deleteHabit,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand)
import App.Domain.HabitTracker.Entity (Habit)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data HabitRepo :: Effect where
  GetHabitsOp :: HabitRepo m [Habit]
  CreateHabitOp :: CreateHabitCommand -> HabitRepo m Habit
  DeleteHabitOp :: Int -> HabitRepo m ()

type instance DispatchOf HabitRepo = Dynamic

getHabitAll :: (HabitRepo :> es) => Eff es [Habit]
getHabitAll = send GetHabitsOp

createHabit :: (HabitRepo :> es) => CreateHabitCommand -> Eff es Habit
createHabit op = send (CreateHabitOp op)

deleteHabit :: (HabitRepo :> es) => Int -> Eff es ()
deleteHabit habitId = send (DeleteHabitOp habitId)
