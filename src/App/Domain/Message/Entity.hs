{-# LANGUAGE DeriveGeneric #-}

module App.Domain.Message.Entity
  ( Message (..),
  )
where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

-- | メッセージのドメインエンティティ
--
--   newtype にすることで String と区別できる型安全性を持つ
--   fromString で作り、unMessage で取り出す
--
--   NOTE: Haskell では orphan instance を避けるため FromJSON/ToJSON を
--   ここで定義する。純粋な DDD では Domain が Aeson に依存しないが、
--   実用上は許容される一般的なトレードオフ。
newtype Message = Message {unMessage :: String}
  deriving (Show, Eq, Generic)

instance FromJSON Message

instance ToJSON Message
