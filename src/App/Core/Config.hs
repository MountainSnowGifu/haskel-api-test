module App.Core.Config
  ( Config (..),
  )
where

data Config = Config {port :: Int, host :: String} deriving (Show)
