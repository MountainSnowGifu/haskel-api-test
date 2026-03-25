{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.HabitTracker.Repository
  ( HabitRepo (..),
    getHabitAll,
  )
where

import App.Domain.HabitTracker.Entity (Habit)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data HabitRepo :: Effect where
  GetHabitAll :: HabitRepo m [Habit]

type instance DispatchOf HabitRepo = Dynamic

getHabitAll :: (HabitRepo :> es) => Eff es [Habit]
getHabitAll = send GetHabitAll
