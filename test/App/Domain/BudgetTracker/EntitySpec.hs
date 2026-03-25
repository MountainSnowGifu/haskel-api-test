{-# LANGUAGE OverloadedStrings #-}

module App.Domain.BudgetTracker.EntitySpec (spec) where

import App.Domain.BudgetTracker.Entity
import Data.Text (Text)
import Test.Hspec

mkRecord :: Int -> Text -> Int -> Record
mkRecord rid rtype amount =
  Record
    { recordId = rid,
      recordUserId = 1,
      recordType = rtype,
      recordCategory = "test",
      recordAmount = amount,
      recordDate = "2026-03",
      recordMemo = ""
    }

spec :: Spec
spec = describe "summarize" $ do
  it "空リストのとき income=0, expense=0, balance=0" $ do
    let result = summarize "2026-03" []
    summaryIncome result `shouldBe` 0
    summaryExpense result `shouldBe` 0
    summaryBalance result `shouldBe` 0

  it "income レコードのみを合計する" $ do
    let records =
          [ mkRecord 1 "income" 1000,
            mkRecord 2 "income" 500
          ]
        result = summarize "2026-03" records
    summaryIncome result `shouldBe` 1500
    summaryExpense result `shouldBe` 0
    summaryBalance result `shouldBe` 1500

  it "expense レコードのみを合計する" $ do
    let records =
          [ mkRecord 1 "expense" 300,
            mkRecord 2 "expense" 200
          ]
        result = summarize "2026-03" records
    summaryIncome result `shouldBe` 0
    summaryExpense result `shouldBe` 500
    summaryBalance result `shouldBe` (-500)

  it "income と expense が混在するとき balance = income - expense" $ do
    let records =
          [ mkRecord 1 "income" 2000,
            mkRecord 2 "expense" 800,
            mkRecord 3 "income" 500,
            mkRecord 4 "expense" 300
          ]
        result = summarize "2026-03" records
    summaryIncome result `shouldBe` 2500
    summaryExpense result `shouldBe` 1100
    summaryBalance result `shouldBe` 1400

  it "summaryMonth に渡した月がそのまま入る" $ do
    let result = summarize "2025-12" []
    summaryMonth result `shouldBe` "2025-12"
