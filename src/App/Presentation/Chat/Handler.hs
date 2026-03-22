{-# LANGUAGE ImportQualifiedPost #-}

module App.Presentation.Chat.Handler
  ( wsHandler,
  )
where

import App.Application.Chat.UseCase (handleEvent, removeClient)
import App.Domain.Chat.Entity (RoomState, MessageStore)
import Control.Exception (finally)
import Control.Monad (forever)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (Value (..), decode)
import Data.ByteString.Lazy (ByteString)
import Data.IORef (newIORef)
import Network.WebSockets qualified as WS
import Servant (Handler)

wsHandler :: RoomState -> MessageStore -> WS.Connection -> Handler ()
wsHandler rooms store conn = liftIO $ do
  clientRef <- newIORef Nothing
  finally
    ( forever $ do
        raw <- WS.receiveData conn :: IO ByteString
        case decode raw of
          Just (Object km) -> handleEvent rooms store conn clientRef km
          _ -> return ()
    )
    (removeClient rooms clientRef)
