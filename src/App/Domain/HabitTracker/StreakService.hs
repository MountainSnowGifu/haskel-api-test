module App.Domain.HabitTracker.StreakService
  ( calcCurrentStreak,
    calcBestStreak,
  )
where

import qualified Data.Set as Set
import Data.Time (Day, addDays, diffDays)

-- 今日から遡って連続している日数を返す
calcCurrentStreak :: Day -> Set.Set Day -> Int
calcCurrentStreak today doneSet = go today 0
  where
    go d acc
      | Set.member d doneSet = go (addDays (-1) d) (acc + 1)
      | otherwise = acc

-- 全期間で最長の連続日数を返す
calcBestStreak :: [Day] -> Int
calcBestStreak [] = 0
calcBestStreak days = maximum $ map length $ groupConsecutive days

-- ソート済みの日付リストを連続する区間ごとにグループ化する
groupConsecutive :: [Day] -> [[Day]]
groupConsecutive [] = []
groupConsecutive (x : xs) = go x [x] xs
  where
    go _ cur [] = [cur]
    go prev cur (y : ys)
      | diffDays y prev == 1 = go y (cur ++ [y]) ys
      | otherwise = cur : go y [y] ys
