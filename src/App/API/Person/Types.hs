module App.API.Person.Types
  ( NameWrapper (..),
  )
where

import Data.Aeson (FromJSON, parseJSON)

newtype NameWrapper = NameWrapper String

instance FromJSON NameWrapper where
  parseJSON v = NameWrapper <$> parseJSON v
