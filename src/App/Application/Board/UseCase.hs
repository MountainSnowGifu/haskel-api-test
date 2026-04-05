{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.UseCase
  ( createBoard,
    fetchAllBoardsPublic,
    deleteBoard,
    fetchBoardPublic,
    updateBoard,
    saveAttachment,
    fetchAttachmentsForBoardPublic,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..), DeleteBoardCommand (..), SaveAttachmentCommand (..), UpdateBoardCommand (..))
import App.Application.Board.PublicRepository (PublicBoardQuery)
import App.Application.Board.PublicRepository qualified as PublicBoardQuery
import App.Application.Board.Repository (BoardRepo)
import App.Application.Board.Repository qualified as BoardRepo
import App.Domain.Board.BoardService (createBoardWithAttachments)
import App.Domain.Board.Entity (Board (..), BoardAttachment, BoardWithAttachments (..))
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Effectful (Eff, (:>))

data BoardValidationError = TitleEmpty | BodyMarkdownEmpty

fetchAllBoardsPublic ::
  (PublicBoardQuery :> es) =>
  Eff es [BoardWithAttachments]
fetchAllBoardsPublic = do
  mBoards <- PublicBoardQuery.getAllPublicBoards
  mapM
    ( \b -> do
        mAtts <- PublicBoardQuery.fetchAttachmentsForBoard (boardId b)
        return $ createBoardWithAttachments b (fromMaybe [] mAtts)
    )
    (fromMaybe [] mBoards)

fetchBoardPublic :: (PublicBoardQuery :> es) => Int -> Eff es (Maybe BoardWithAttachments)
fetchBoardPublic bid = do
  mBoard <- PublicBoardQuery.getPublicBoard bid
  case mBoard of
    Nothing -> return Nothing
    Just b -> do
      mAtts <- PublicBoardQuery.fetchAttachmentsForBoard (boardId b)
      return $ Just $ createBoardWithAttachments b (fromMaybe [] mAtts)

fetchAttachmentsForBoardPublic :: (PublicBoardQuery :> es) => Int -> Eff es (Maybe [BoardAttachment])
fetchAttachmentsForBoardPublic = PublicBoardQuery.fetchAttachmentsForBoard

createBoard ::
  (BoardRepo :> es, PublicBoardQuery :> es) =>
  CreateBoardCommand ->
  Eff es (Either BoardValidationError (Maybe BoardWithAttachments))
createBoard cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right cmd' -> do
    mBoard <- BoardRepo.createBoard cmd'
    case mBoard of
      Nothing -> return $ Right Nothing
      Just b -> do
        mAtts <- PublicBoardQuery.fetchAttachmentsForBoard (boardId b)
        return $ Right $ Just $ createBoardWithAttachments b (fromMaybe [] mAtts)

validateCreate :: CreateBoardCommand -> Either BoardValidationError CreateBoardCommand
validateCreate cmd@(CreateBoardCommand {cmdBoardTitle = title, cmdBoardBodyMarkdown = body})
  | T.null title = Left TitleEmpty
  | T.null body = Left BodyMarkdownEmpty
  | otherwise = Right cmd

deleteBoard :: (BoardRepo :> es) => DeleteBoardCommand -> Eff es Bool
deleteBoard = BoardRepo.deleteBoard

updateBoard :: (BoardRepo :> es, PublicBoardQuery :> es) => UpdateBoardCommand -> Eff es (Maybe BoardWithAttachments)
updateBoard cmd = do
  mBoard <- BoardRepo.updateBoard cmd
  case mBoard of
    Nothing -> return Nothing
    Just b -> do
      mAtts <- PublicBoardQuery.fetchAttachmentsForBoard (boardId b)
      return $ Just $ createBoardWithAttachments b (fromMaybe [] mAtts)

saveAttachment :: (BoardRepo :> es) => SaveAttachmentCommand -> Eff es (Maybe BoardAttachment)
saveAttachment = BoardRepo.saveAttachment
