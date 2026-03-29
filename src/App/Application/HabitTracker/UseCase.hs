{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.HabitTracker.UseCase
  ( fetchAllHabits,
    fetchHabit,
    HabitValidationError (..),
    createHabit,
    deleteHabit,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..), DeleteHabitCommand (..))
import App.Application.HabitTracker.Repository (HabitRepo, getHabitAll)
import App.Application.HabitTracker.Repository qualified as HabitRepo
import App.Domain.HabitTracker.Entity (Habit (..), HabitLog (..), HabitWithStats (..))
import App.Domain.HabitTracker.StreakService (calcBestStreak, calcCurrentStreak)
import Data.List (find, sort)
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Time (Day, getCurrentTime, utctDay)
import Effectful (Eff, IOE, liftIO, (:>))

data HabitValidationError = CategoryEmpty | ColorEmpty

fetchAllHabits :: (HabitRepo :> es, IOE :> es) => Eff es [HabitWithStats]
fetchAllHabits = do
  pairs <- getHabitAll
  today <- liftIO $ utctDay <$> getCurrentTime
  return $ map (toHabitWithStats today) pairs

fetchHabit :: (HabitRepo :> es, IOE :> es) => Int -> Eff es (Maybe HabitWithStats)
fetchHabit hid = do
  pairs <- getHabitAll
  today <- liftIO $ utctDay <$> getCurrentTime
  return $ toHabitWithStats today <$> find (\(h, _) -> habitId h == hid) pairs

-- ドメインサービスを呼んで HabitWithStats を組み立てる
toHabitWithStats :: Day -> (Habit, [HabitLog]) -> HabitWithStats
toHabitWithStats today (habit, logs) =
  let doneDays = sort [habitLogDate l | l <- logs, habitLogStatus l == "done"]
      doneSet = Set.fromList doneDays
   in HabitWithStats
        { hwsHabit = habit,
          hwsCurrentStreak = calcCurrentStreak today doneSet,
          hwsBestStreak = calcBestStreak doneDays,
          hwsTotalCompletions = length doneDays,
          hwsTodayCompleted = Set.member today doneSet
        }

validateCreate :: CreateHabitCommand -> Either HabitValidationError CreateHabitCommand
validateCreate cmd
  | T.null (cmdHabitCategory cmd) = Left CategoryEmpty
  | T.null (cmdHabitColor cmd) = Left ColorEmpty
  | otherwise = Right cmd

createHabit ::
  (HabitRepo :> es) =>
  CreateHabitCommand ->
  Eff es (Either HabitValidationError HabitWithStats)
createHabit cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right cmd' -> do
    habit <- HabitRepo.createHabit cmd'
    -- 新規作成直後はログが存在しないため統計は全て初期値
    return $ Right $ HabitWithStats habit 0 0 0 False

deleteHabit :: (HabitRepo :> es) => DeleteHabitCommand -> Eff es ()
deleteHabit (DeleteHabitCommand hid) = HabitRepo.deleteHabit hid
