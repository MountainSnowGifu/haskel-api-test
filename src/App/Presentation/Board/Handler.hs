{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

module App.Presentation.Board.Handler
  ( postBoardHandler,
    BoardRunner,
    PublicBoardRunner,
    getBoardsHandler,
    deleteBoardHandler,
    getBoardHandler,
    updateBoardHandler,
    uploadAttachmentHandler,
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.Board.Command (DeleteBoardCommand (..), SaveAttachmentCommand (..))
import App.Application.Board.PublicRepository (PublicBoardQuery)
import App.Application.Board.Repository (BoardRepo)
import App.Application.Board.UseCase
  ( createBoard,
    deleteBoard,
    fetchAllBoardsPublic,
    fetchBoardPublic,
    saveAttachment,
    updateBoard,
  )
import App.Domain.Board.Entity (BoardWithAttachments (..))
import App.Domain.Board.ValueObject (BoardId (..))
import App.Presentation.Board.Request
  ( PostBoardRequest,
    PutBoardRequest,
    toCreateBoardCommand,
    toUpdateBoardCommand,
  )
import App.Presentation.Board.Response
  ( AttachmentResponse (..),
    BoardResponse (..),
    CreatedBoardResponse (..),
    toAttachmentResponse,
    toBoardResponse,
    toCreatedBoardResponse,
  )
import Control.Exception (SomeException, try)
import Control.Monad.IO.Class (liftIO)
import Data.Char (toLower)
import Data.Text (pack, unpack)
import Data.UUID (toText)
import Data.UUID.V4 (nextRandom)
import Effectful (Eff, IOE)
import Servant
import Servant.Multipart (MultipartData, Tmp, fdFileName, fdPayload, files)
import System.Directory (copyFile, getFileSize)
import System.FilePath (takeExtension)

type BoardRunner = forall a. Eff '[BoardRepo, PublicBoardQuery, IOE] a -> IO a

type PublicBoardRunner = forall a. Eff '[PublicBoardQuery, IOE] a -> IO a

getBoardHandler :: PublicBoardRunner -> Int -> Handler BoardResponse
getBoardHandler runPublic bid = do
  result <- liftIO $ runPublic (fetchBoardPublic (BoardId bid))
  case result of
    Nothing -> throwError err404
    Just b -> return (toBoardResponse b)

getBoardsHandler :: PublicBoardRunner -> Handler [BoardResponse]
getBoardsHandler runPublic = do
  boards <- liftIO $ runPublic fetchAllBoardsPublic
  return (map toBoardResponse boards)

postBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> PostBoardRequest -> Handler CreatedBoardResponse
postBoardHandler mkRun user req = do
  result <- liftIO $ mkRun user (createBoard (toCreateBoardCommand req))
  case result of
    Left _ -> throwError err400 {errBody = "Failed to create board."}
    Right Nothing -> throwError err400 {errBody = "Failed to create board."}
    Right (Just bwa) -> return (toCreatedBoardResponse (board bwa))

deleteBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> Handler NoContent
deleteBoardHandler mkRun user hid = do
  deleted <- liftIO $ mkRun user (deleteBoard (DeleteBoardCommand hid))
  if deleted then return NoContent else throwError err404

updateBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> PutBoardRequest -> Handler BoardResponse
updateBoardHandler mkRun user bid req = do
  result <- liftIO $ mkRun user (updateBoard (toUpdateBoardCommand bid req))
  case result of
    Nothing -> throwError err404
    Just b -> return (toBoardResponse b)

uploadAttachmentHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> MultipartData Tmp -> Handler AttachmentResponse
uploadAttachmentHandler mkRun user bid multipart = case files multipart of
  [] -> throwError err400 {errBody = "No file provided."}
  (f : _) -> do
    let ext = map toLower $ takeExtension (unpack (fdFileName f))
    -- 拡張子検証
    if ext `notElem` allowedExtensions
      then throwError err400 {errBody = "File type not allowed."}
      else do
        -- サイズ検証 (10MB上限)
        fileSize <- liftIO $ getFileSize (fdPayload f)
        if fileSize > maxFileSize
          then throwError err400 {errBody = "File too large. Max 10MB."}
          else do
            uuid <- liftIO nextRandom
            let filename = toText uuid <> pack ext
                dest = "static/board/uploads/" <> unpack filename
                url = "/api/board/uploads/" <> filename
            -- DB保存を先に行い、孤児ファイルを防ぐ
            result <- liftIO $ mkRun user (saveAttachment (SaveAttachmentCommand bid (toText uuid) url))
            case result of
              Nothing -> throwError err500 {errBody = "Failed to save attachment."}
              Just attachment -> do
                copyResult <- liftIO $ try $ copyFile (fdPayload f) dest
                case copyResult of
                  Left (_ :: SomeException) -> throwError err500 {errBody = "Failed to save file."}
                  Right _ -> return (toAttachmentResponse attachment)

allowedExtensions :: [String]
allowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".pdf"]

maxFileSize :: Integer
maxFileSize = 10 * 1024 * 1024
