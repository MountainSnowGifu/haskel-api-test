module App.Presentation.Message.Handler
  ( postMessageHandler,
    getMessagesHandler,
  )
where

import App.Application.Message.UseCase (getMessages, postMessage)
import App.Domain.Message.Entity (Message)
import App.Infrastructure.Repository.MessageSQLite (runMessageRepoSQLite)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant (Handler, NoContent (..))

-- | POST /message ハンドラ
--
--   型の流れ:
--     Eff '[MessageRepo, IOE] ()
--       → (runMessageRepoSQLite) → Eff '[IOE] ()
--       → (runEff)               → IO ()
--       → (liftIO)               → Handler ()
postMessageHandler :: FilePath -> Message -> Handler NoContent
postMessageHandler dbfile msg = do
  liftIO $ runEff $ runMessageRepoSQLite dbfile $ postMessage msg
  return NoContent

-- | GET /message ハンドラ
getMessagesHandler :: FilePath -> Handler [Message]
getMessagesHandler dbfile =
  liftIO $ runEff $ runMessageRepoSQLite dbfile getMessages
