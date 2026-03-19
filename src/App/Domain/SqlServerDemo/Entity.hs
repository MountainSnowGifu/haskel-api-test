module App.Domain.SqlServerDemo.Entity
  ( SqlResult (..),
  )
where

-- | SQL Server デモのドメインエンティティ
--
--   newtype で String と区別し、型安全性を確保する
newtype SqlResult = SqlResult {unSqlResult :: String}
  deriving (Show, Eq)
