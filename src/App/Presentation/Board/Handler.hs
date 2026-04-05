{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.Board.Handler
  ( postBoardHandler,
    BoardRunner,
    getBoardsHandler,
    deleteBoardHandler,
    getBoardHandler,
    updateBoardHandler,
    uploadAttachmentHandler,
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.Board.Command (DeleteBoardCommand (..), SaveAttachmentCommand (..))
import App.Application.Board.Repository (BoardRepo)
import App.Application.Board.UseCase (createBoard, deleteBoard, fetchAllBoardsPublic, fetchBoardPublic, saveAttachment, updateBoard)
import App.Presentation.Board.Request (PostBoardRequest, PutBoardRequest, toCreateBoardCommand, toUpdateBoardCommand)
import App.Presentation.Board.Response
  ( AttachmentResponse (..),
    BoardResponse (..),
    CreatedBoardResponse (..),
    toBoardResponse,
    toCreatedBoardResponse,
  )
import Control.Monad.IO.Class (liftIO)
import Data.Text (pack, unpack)
import Data.UUID (toText)
import Data.UUID.V4 (nextRandom)
import Effectful (Eff, IOE)
import Servant
import Servant.Multipart (MultipartData, Tmp, fdFileName, fdPayload, files)
import System.Directory (copyFile)
import System.FilePath (takeExtension)

type BoardRunner = forall a. Eff '[BoardRepo, IOE] a -> IO a

postBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> PostBoardRequest -> Handler CreatedBoardResponse
postBoardHandler mkRun user req = do
  result <- liftIO $ mkRun user (createBoard (toCreateBoardCommand req))
  case result of
    Left _ -> throwError err400 {errBody = "Failed to create board."}
    Right Nothing -> throwError err400 {errBody = "Failed to create board."}
    Right (Just board) -> return (toCreatedBoardResponse board)

getBoardsHandler :: BoardRunner -> Handler [BoardResponse]
getBoardsHandler runPublic = do
  boards <- liftIO $ runPublic fetchAllBoardsPublic
  return (map toBoardResponse boards)

deleteBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> Handler NoContent
deleteBoardHandler mkRun user hid = do
  liftIO $ mkRun user (deleteBoard (DeleteBoardCommand hid))
  return NoContent

getBoardHandler :: BoardRunner -> Int -> Handler BoardResponse
getBoardHandler runPublic bid = do
  result <- liftIO $ runPublic (fetchBoardPublic bid)
  case result of
    Nothing -> throwError err404
    Just board -> return (toBoardResponse board)

updateBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> PutBoardRequest -> Handler BoardResponse
updateBoardHandler mkRun user bid req = do
  result <- liftIO $ mkRun user (updateBoard (toUpdateBoardCommand bid req))
  case result of
    Nothing -> throwError err404
    Just board -> return (toBoardResponse board)

uploadAttachmentHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> MultipartData Tmp -> Handler AttachmentResponse
uploadAttachmentHandler mkRun user multipart = case files multipart of
  [] -> throwError err400 {errBody = "No file provided."}
  (f : _) -> do
    uuid <- liftIO nextRandom
    let ext = takeExtension (unpack (fdFileName f))
        filename = toText uuid <> pack ext
        dest = "static/board/uploads/" <> unpack filename
        url = "/board/uploads/" <> filename
    liftIO $ copyFile (fdPayload f) dest
    liftIO $ mkRun user (saveAttachment (SaveAttachmentCommand (toText uuid) url))
    return $
      AttachmentResponse
        { attachmentId = toText uuid,
          attachmentUrl = url
        }
