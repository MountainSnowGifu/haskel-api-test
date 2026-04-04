module App.Core.Config
  ( Config (..),
    LogFormat (..),
    LogLevel (..),
  )
where

data LogLevel = Debug | Info | Warn | Error
  deriving (Eq, Ord, Show, Read)

data LogFormat = Csv | Json
  deriving (Eq, Show, Read)

data Config = Config
  { port :: Int,
    host :: String,
    logLevel :: LogLevel,
    logFormat :: LogFormat,
    logFilePath :: FilePath
  }
  deriving (Show)
