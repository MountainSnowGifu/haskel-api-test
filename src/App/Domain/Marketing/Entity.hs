{-# LANGUAGE DeriveGeneric #-}

module App.Domain.Marketing.Entity
  ( ClientInfo (..),
    Email (..),
  )
where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

-- | マーケティング対象の顧客情報
--
--   型:
--     ClientInfo :: { clientName :: String, clientEmail :: String
--                   , clientAge :: Int, clientInterestedIn :: [String] }
--
--   NOTE: FromJSON/ToJSON は orphan instance を避けるため Domain で定義する。
--   純粋な DDD では Domain が Aeson に依存しないが、実用上は許容される。
data ClientInfo = ClientInfo
  { clientName :: String,
    clientEmail :: String,
    clientAge :: Int,
    clientInterestedIn :: [String]
  }
  deriving (Generic)

instance FromJSON ClientInfo

instance ToJSON ClientInfo

-- | 生成されたメールのエンティティ
--
--   型: Email :: { from :: String, to :: String, subject :: String, body :: String }
data Email = Email
  { from :: String,
    to :: String,
    subject :: String,
    body :: String
  }
  deriving (Generic)

instance ToJSON Email
