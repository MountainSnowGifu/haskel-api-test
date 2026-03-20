{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Auth.API
  ( LoginAPI,
    LoginRequest (..),
    TokenResponse (..),
  )
where

import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Text as T
import GHC.Generics (Generic)
import Servant

-- | HTTP リクエストボディ: { "loginUsername": "john", "loginPassword": "shhhh" }
--
--   Domain の Username/Password とは別の型。
--   Presentation 層が HTTP の関心事（JSON フォーマット等）を担う。
data LoginRequest = LoginRequest
  { username :: T.Text,
    password :: T.Text
  }
  deriving (Show, Generic)

instance FromJSON LoginRequest

-- | HTTP レスポンスボディ: { "token": "550e8400-..." }
newtype TokenResponse = TokenResponse
  { token :: T.Text
  }
  deriving (Show, Generic)

instance ToJSON TokenResponse

type LoginAPI = "login" :> ReqBody '[JSON] LoginRequest :> Post '[JSON] TokenResponse
