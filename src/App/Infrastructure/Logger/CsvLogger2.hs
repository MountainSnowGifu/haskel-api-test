{-# LANGUAGE OverloadedStrings #-}

module App.Infrastructure.Logger.CsvLogger2
  ( csvLogger2,
  )
where

import Control.Monad (when)
import qualified Data.ByteString.Char8 as BS
import Data.Time (NominalDiffTime, diffUTCTime, getCurrentTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Network.HTTP.Types (Status (..))
import Network.Wai (Middleware, rawPathInfo, requestMethod, responseStatus)
import System.IO (IOMode (..), hFileSize, hPutStrLn, withFile)

-- | WAI ミドルウェア: 全リクエストの動作ログを CSV ファイルに追記する
--
-- 型シグネチャ:
--   csvLogger2 :: FilePath -> Middleware
--   Middleware = Application -> Application
--   Application = Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived
--
-- 使い方:
--   app = csvLogger2 "access.csv" $ cors ... $ serve ...
csvLogger2 :: FilePath -> Middleware
csvLogger2 csvPath app req respond = do
  startTime <- getCurrentTime
  app req $ \response -> do
    endTime <- getCurrentTime
    let status = responseStatus response
        method = BS.unpack (requestMethod req)
        path = BS.unpack (rawPathInfo req)
        code = statusCode status
        latencyMs = toMillis (diffUTCTime endTime startTime)
        timestamp = formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" startTime
    appendLogLine csvPath timestamp method path code latencyMs
    respond response

-- NominalDiffTime をミリ秒の整数値に変換
toMillis :: NominalDiffTime -> Int
toMillis dt = round (realToFrac dt * (1000 :: Double))

-- CSV ファイルへ1行追記する。ファイルが空なら先にヘッダー行を書く
appendLogLine :: FilePath -> String -> String -> String -> Int -> Int -> IO ()
appendLogLine csvPath timestamp method path code latencyMs =
  withFile csvPath AppendMode $ \h -> do
    size <- hFileSize h
    when (size == 0) $
      hPutStrLn h "timestamp,method,path,status_code,latency_ms"
    hPutStrLn h $
      timestamp
        ++ ","
        ++ method
        ++ ","
        ++ path
        ++ ","
        ++ show code
        ++ ","
        ++ show latencyMs
