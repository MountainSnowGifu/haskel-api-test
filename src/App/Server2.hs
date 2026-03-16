{-# LANGUAGE OverloadedStrings #-}

module App.Server2
  ( AppM,
    nt,
    server2,
  )
where

import App.API (API2)
import App.Config (Config (..))
import App.Types
import Control.Monad.Error.Class
import Control.Monad.Reader
import qualified Data.ByteString.Lazy.Char8 as BSL
import Servant

-- カスタムモナド: Config を環境として持つ ReaderT
type AppM = ReaderT Config Handler

-- AppM を Handler に変換する自然変換
nt :: Config -> AppM a -> Handler a
nt config action = runReaderT action config

server2 :: ServerT API2 AppM
server2 =
  handlerAge
    :<|> handlerName
    :<|> handlerName'
    :<|> handlerWithError
  where
    handlerAge :: AppM String
    handlerAge = do
      cfg <- ask
      return (host cfg ++ ":" ++ show (port cfg) ++ ":31")

    handlerName :: NameWrapper -> AppM String
    handlerName (NameWrapper nameIn) = return ("name: " ++ nameIn)

    handlerName' :: NameWrapper -> AppM String
    handlerName' (NameWrapper nameIn) = do
      liftIO $ print $ "input name = " ++ nameIn
      return nameIn

    handlerWithError :: AppM String
    handlerWithError =
      if True
        then throwError $ err500 {errBody = BSL.pack "Exception in module A.B.C:55.  Have a great day!"}
        else return "sras"
