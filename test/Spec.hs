module Main where

import Test.Hspec
import qualified App.Domain.BudgetTracker.EntitySpec
import qualified App.Presentation.Task.APISpec
import qualified App.Presentation.Board.APISpec

main :: IO ()
main = hspec $ do
  App.Domain.BudgetTracker.EntitySpec.spec
  App.Presentation.Task.APISpec.spec
  App.Presentation.Board.APISpec.spec
