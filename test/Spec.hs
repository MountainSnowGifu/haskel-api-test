module Main where

import Test.Hspec
import qualified App.Domain.BudgetTracker.EntitySpec

main :: IO ()
main = hspec $ do
  App.Domain.BudgetTracker.EntitySpec.spec
