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
    deleteAttachmentHandler,
    getBoardCategoriesHandler,
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.Board.Command (DeleteAttachmentCommand (..), DeleteBoardCommand (..), SaveAttachmentCommand (..))
import App.Application.Board.PublicRepository (PublicBoardQuery)
import App.Application.Board.Repository (BoardRepo, getBoardCategories)
import App.Application.Board.UseCase
  ( BoardValidationError (..),
    createBoard,
    deleteAttachment,
    deleteBoard,
    fetchAllBoardsPublic,
    fetchBoardPublic,
    saveAttachment,
    updateBoard,
  )
import App.Domain.Board.Entity (BoardAttachment (..), BoardWithAttachments (..))
import App.Domain.Board.ValueObject (AttachmentFileName (..), BoardId (..))
import App.Infrastructure.File.FileStore (UploadError (..), UploadPlan (..), commitUpload, deleteUploadedFile, prepareUpload)
import App.Presentation.Board.Request
  ( PostBoardRequest,
    PutBoardRequest,
    toCreateBoardCommand,
    toUpdateBoardCommand,
  )
import App.Presentation.Board.Response
  ( AttachmentResponse (..),
    BoardCategoryResponse,
    BoardResponse (..),
    CreatedBoardResponse (..),
    toAttachmentResponse,
    toBoardCategoryResponse,
    toBoardResponse,
    toCreatedBoardResponse,
  )
import Control.Exception (SomeException, try)
import Control.Monad.IO.Class (liftIO)
import Data.Text (pack, unpack)
import Effectful (Eff, IOE)
import Servant
import Servant.Multipart (MultipartData, Tmp, fdFileName, fdPayload, files)

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
    Left TitleEmpty -> throwError err422 {errBody = "Title cannot be empty."}
    Left BodyMarkdownEmpty -> throwError err422 {errBody = "Body cannot be empty."}
    Right Nothing -> throwError err400 {errBody = "Failed to create board."}
    Right (Just bwa) -> return (toCreatedBoardResponse (board bwa))

deleteBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> Handler NoContent
deleteBoardHandler mkRun user hid = do
  deleted <- liftIO $ mkRun user (deleteBoard (DeleteBoardCommand hid))
  if deleted then return NoContent else throwError err404

deleteAttachmentHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> String -> Handler NoContent
deleteAttachmentHandler mkRun user bid aid = do
  result <- liftIO $ mkRun user (deleteAttachment (DeleteAttachmentCommand bid (pack aid)))
  case result of
    Nothing -> throwError err404
    Just attachment -> do
      let AttachmentFileName fname = attachmentFileName attachment
      liftIO $ deleteUploadedFile bid fname
      return NoContent

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
    liftIO $ print (fdFileName f) -- デバッグ用: アップロードされたファイル名をログに出力
    planResult <- liftIO $ prepareUpload (fdPayload f) bid (unpack (fdFileName f))
    case planResult of
      Left FileTypeNotAllowed -> throwError err400 {errBody = "File type not allowed."}
      Left FileTooLarge -> throwError err400 {errBody = "File too large. Max 10MB."}
      Right plan -> do
        -- DB保存を先に行い、孤児ファイルを防ぐ
        dbResult <- liftIO $ mkRun user (saveAttachment (SaveAttachmentCommand bid (planFileId plan) (planUrl plan) (planFileName plan)))
        case dbResult of
          Nothing -> throwError err500 {errBody = "Failed to save attachment."}
          Just attachment -> do
            copyResult <- liftIO $ try $ commitUpload (fdPayload f) plan
            case copyResult of
              Left (_ :: SomeException) -> throwError err500 {errBody = "Failed to save file."}
              Right _ -> return (toAttachmentResponse attachment)

getBoardCategoriesHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Handler [BoardCategoryResponse]
getBoardCategoriesHandler mkRun user = do
  categories <- liftIO $ mkRun user getBoardCategories
  return (map toBoardCategoryResponse categories)
