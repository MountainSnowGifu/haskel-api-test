{-# LANGUAGE OverloadedStrings #-}

module App.Infrastructure.Logger.JsonLogger
  ( jsonLogger,
  )
where

import App.Core.Config (LogLevel (..))
import Control.Monad (when)
import Data.Aeson (encode, object, (.=))
import qualified Data.ByteString.Char8 as BS
import qualified Data.ByteString.Lazy.Char8 as BL
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.Time (NominalDiffTime, diffUTCTime, getCurrentTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import qualified Data.UUID as UUID
import qualified Data.UUID.V4 as UUIDv4
import Network.HTTP.Types (HeaderName, Status (..))
import Network.Wai (Middleware, mapResponseHeaders, rawPathInfo, requestHeaders, requestMethod, responseStatus)
import System.IO (IOMode (..), hPutStrLn, withFile)

jsonLogger :: FilePath -> LogLevel -> Middleware
jsonLogger logPath minLevel app req respond = do
  requestId <- maybe mkRequestId pure (lookup requestIdHeader (requestHeaders req))
  startTime <- getCurrentTime
  app req $ \response -> do
    endTime <- getCurrentTime
    let status = responseStatus response
        method = decodeUtf8WithFallback (requestMethod req)
        path = decodeUtf8WithFallback (rawPathInfo req)
        code = statusCode status
        latencyMs = toMillis (diffUTCTime endTime startTime)
        timestamp = T.pack (formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S%QZ" startTime)
        level = levelFromStatus code
        response' = mapResponseHeaders (upsertHeader requestIdHeader requestId) response
    when (shouldLog minLevel level) $
      appendJsonLog logPath timestamp level requestId method path code latencyMs
    respond response'

toMillis :: NominalDiffTime -> Int
toMillis dt = round (realToFrac dt * (1000 :: Double))

shouldLog :: LogLevel -> LogLevel -> Bool
shouldLog minLevel current = current >= minLevel

levelFromStatus :: Int -> LogLevel
levelFromStatus code
  | code >= 500 = Error
  | code >= 400 = Warn
  | otherwise = Info

decodeUtf8WithFallback :: BS.ByteString -> Text
decodeUtf8WithFallback = TE.decodeUtf8With (\_ _ -> Just '?')

appendJsonLog :: FilePath -> Text -> LogLevel -> BS.ByteString -> Text -> Text -> Int -> Int -> IO ()
appendJsonLog logPath timestamp level requestId method path code latencyMs =
  withFile logPath AppendMode $ \h ->
    BL.hPutStrLn h $
      encode $
        object
          [ "timestamp" .= timestamp,
            "level" .= show level,
            "request_id" .= decodeUtf8WithFallback requestId,
            "method" .= method,
            "path" .= path,
            "status_code" .= code,
            "latency_ms" .= latencyMs
          ]

requestIdHeader :: HeaderName
requestIdHeader = "X-Request-Id"

mkRequestId :: IO BS.ByteString
mkRequestId = BS.pack . UUID.toString <$> UUIDv4.nextRandom

upsertHeader :: HeaderName -> BS.ByteString -> [(HeaderName, BS.ByteString)] -> [(HeaderName, BS.ByteString)]
upsertHeader name value headers = (name, value) : filter ((/= name) . fst) headers
