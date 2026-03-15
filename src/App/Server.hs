{-# LANGUAGE OverloadedStrings #-}

module App.Server
  ( runServant,
  )
where

import App.API (API1, API2, API3, Message, combinedAPI)
import App.Config (Config (..))
import App.Types
import Control.Monad.Error.Class
import Control.Monad.Reader
import qualified Data.ByteString.Lazy.Char8 as BSL
import Data.List (intercalate)
import Database.SQLite.Simple (execute, query_, withConnection)
import Database.SQLite.Simple.Types (Only (..))
import Network.Wai.Handler.Warp (run)
import Servant

emailForClient :: ClientInfo -> Email
emailForClient c = Email from' to' subject' body'
  where
    from' = "great@company.com"
    to' = clientEmail c
    subject' = "Hey " ++ clientName c ++ ", we miss you!"
    body' =
      "Hi "
        ++ clientName c
        ++ ",\n\n"
        ++ "Since you've recently turned "
        ++ show (clientAge c)
        ++ ", have you checked out our latest "
        ++ intercalate ", " (clientInterestedIn c)
        ++ " products? Give us a visit!"

server1 :: Server API1
server1 =
  position
    :<|> hello
    :<|> marketing
  where
    position :: Int -> Int -> Handler Position
    position x y = return (Position x y)

    hello :: Maybe String -> Handler HelloMessage
    hello mname = return . HelloMessage $ case mname of
      Nothing -> "Hello, anonymous coward"
      Just n -> "Hello, " ++ n

    marketing :: ClientInfo -> Handler Email
    marketing clientinfo = return (emailForClient clientinfo)

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
      if True -- If there was an error ?
        then throwError $ err500 {errBody = BSL.pack "Exception in module A.B.C:55.  Have a great day!"} -- We throw error here. Read more about it below.
        else return "sras" -- else return result.

server3 :: FilePath -> Server API3
server3 dbfile = postMessage :<|> getMessages
  where
    postMessage :: Message -> Handler NoContent
    postMessage message = do
      liftIO . withConnection dbfile $ \conn ->
        execute
          conn
          "INSERT INTO messages VALUES (?)"
          (Only message)
      return NoContent

    getMessages :: Handler [Message]
    getMessages = fmap (map fromOnly) . liftIO $
      withConnection dbfile $ \conn ->
        query_ conn "SELECT msg FROM messages"

app :: Config -> Application
app config =
  serve combinedAPI $
    server1 :<|> hoistServer (Proxy :: Proxy API2) (nt config) server2 :<|> server3 "mydb"

runServant :: Config -> IO ()
runServant config = run (port config) (app config)
