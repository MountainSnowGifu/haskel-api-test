{-# LANGUAGE DeriveGeneric #-}

module App.Domain.Person.Entity
  ( NameWrapper (..),
  )
where

import Data.Aeson (FromJSON, parseJSON)

-- | 名前のリクエストボディを包むエンティティ
--
--   型: NameWrapper :: String -> NameWrapper
--
--   JSON の文字列をそのまま受け取る。
--   newtype にすることで String と区別できる型安全性を持つ。
newtype NameWrapper = NameWrapper String

instance FromJSON NameWrapper where
  parseJSON v = NameWrapper <$> parseJSON v
