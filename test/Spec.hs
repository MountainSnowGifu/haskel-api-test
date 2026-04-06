module Main where

import Test.Hspec
import qualified App.Domain.BudgetTracker.EntitySpec
import qualified App.Presentation.Task.APISpec

main :: IO ()
main = hspec $ do
  App.Domain.BudgetTracker.EntitySpec.spec
  App.Presentation.Task.APISpec.spec
