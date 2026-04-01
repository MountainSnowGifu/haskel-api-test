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
    updateHabit,
    createHabitLog,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..), CreateHabitLogCommand (..), UpdateHabitCommand (..))
import App.Domain.HabitTracker.Entity (Habit, HabitLog)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data HabitRepo :: Effect where
  -- 生データを返す。ストリーク計算は Application 層の責務。
  GetHabitsOp :: HabitRepo m [(Habit, [HabitLog])]
  CreateHabitOp :: CreateHabitCommand -> HabitRepo m (Maybe Habit)
  DeleteHabitOp :: Int -> HabitRepo m ()
  UpdateHabitOp :: Int -> UpdateHabitCommand -> HabitRepo m (Maybe Habit)
  CreateHabitLogOp :: Int -> CreateHabitLogCommand -> HabitRepo m (Maybe ())

type instance DispatchOf HabitRepo = Dynamic

getHabitAll :: (HabitRepo :> es) => Eff es [(Habit, [HabitLog])]
getHabitAll = send GetHabitsOp

createHabit :: (HabitRepo :> es) => CreateHabitCommand -> Eff es (Maybe Habit)
createHabit op = send (CreateHabitOp op)

deleteHabit :: (HabitRepo :> es) => Int -> Eff es ()
deleteHabit habitId = send (DeleteHabitOp habitId)

updateHabit :: (HabitRepo :> es) => Int -> UpdateHabitCommand -> Eff es (Maybe Habit)
updateHabit habitId cmd = send (UpdateHabitOp habitId cmd)

createHabitLog :: (HabitRepo :> es) => Int -> CreateHabitLogCommand -> Eff es (Maybe ())
createHabitLog habitId cmd = send (CreateHabitLogOp habitId cmd)
