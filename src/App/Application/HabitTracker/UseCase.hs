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
    updateHabit,
    createHabitLog,
    fetchHabitLogs,
  )
where

import App.Application.HabitTracker.Command (CreateHabitCommand (..), CreateHabitLogCommand (..), DeleteHabitCommand (..), FetchHabitLogsCommand (..), UpdateHabitCommand (..))
import App.Application.HabitTracker.Repository (HabitRepo, getHabitAll)
import App.Application.HabitTracker.Repository qualified as HabitRepo
import App.Domain.HabitTracker.Entity (Habit (..), HabitLog (..), HabitWithLogs (..), HabitWithStats (..))
import App.Domain.HabitTracker.StreakService (calcBestStreak, calcCurrentStreak)
import Data.List (find, sort)
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Time (Day, getCurrentTime, toGregorian, utctDay)
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
  let doneDays = sort [habitLogDate l | l <- logs, habitLogStatus l == "completed"]
      doneSet = Set.fromList doneDays
   in HabitWithStats
        { hwsHabit = habit,
          hwsCurrentStreak = calcCurrentStreak today doneSet,
          hwsBestStreak = calcBestStreak doneDays,
          hwsTotalCompletions = length doneDays,
          hwsTodayCompleted = Set.member today doneSet
        }

fetchHabitLogs :: (HabitRepo :> es) => FetchHabitLogsCommand -> Eff es [HabitWithLogs]
fetchHabitLogs (FetchHabitLogsCommand year month) = do
  pairs <- getHabitAll
  let filteredPairs = [(h, filter (\l -> let (y, m, _) = toGregorian (habitLogDate l) in y == fromIntegral year && m == month) ls) | (h, ls) <- pairs]
  return $ map toHabitWithLogs filteredPairs

toHabitWithLogs :: (Habit, [HabitLog]) -> HabitWithLogs
toHabitWithLogs (habit, logs) = HabitWithLogs habit logs

createHabit ::
  (HabitRepo :> es) =>
  CreateHabitCommand ->
  Eff es (Either HabitValidationError (Maybe HabitWithStats))
createHabit cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right cmd' -> do
    mHabit <- HabitRepo.createHabit cmd'
    -- 新規作成直後はログが存在しないため統計は全て初期値
    return $ Right $ fmap (\habit -> HabitWithStats habit 0 0 0 False) mHabit

validateCreate :: CreateHabitCommand -> Either HabitValidationError CreateHabitCommand
validateCreate cmd
  | T.null (cmdHabitCategory cmd) = Left CategoryEmpty
  | T.null (cmdHabitColor cmd) = Left ColorEmpty
  | otherwise = Right cmd

deleteHabit :: (HabitRepo :> es) => DeleteHabitCommand -> Eff es Bool
deleteHabit (DeleteHabitCommand hid) = HabitRepo.deleteHabit hid

updateHabit :: (HabitRepo :> es) => UpdateHabitCommand -> Eff es (Maybe Habit)
updateHabit cmd = do
  let hid = cmdUpdateHabitId cmd
  HabitRepo.updateHabit hid cmd

createHabitLog :: (HabitRepo :> es) => CreateHabitLogCommand -> Eff es (Maybe ())
createHabitLog cmd@(CreateHabitLogCommand hid _) =
  HabitRepo.createHabitLog hid cmd
