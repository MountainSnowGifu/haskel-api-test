{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.UseCase
  ( createBoard,
    fetchAllBoards,
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
import Data.Text qualified as T
import Effectful (Eff, (:>))

data BoardValidationError = TitleEmpty | BodyMarkdownEmpty

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
        atts <- PublicBoardQuery.fetchAttachmentsForBoard (boardId b)
        return $ Right $ Just $ createBoardWithAttachments b atts

validateCreate :: CreateBoardCommand -> Either BoardValidationError CreateBoardCommand
validateCreate cmd@(CreateBoardCommand {cmdBoardTitle = title, cmdBoardBodyMarkdown = body})
  | T.null title = Left TitleEmpty
  | T.null body = Left BodyMarkdownEmpty
  | otherwise = Right cmd

fetchAllBoards ::
  (BoardRepo :> es) =>
  Eff es [Board]
fetchAllBoards = BoardRepo.getAllBoards

fetchAllBoardsPublic ::
  (PublicBoardQuery :> es) =>
  Eff es [Board]
fetchAllBoardsPublic = PublicBoardQuery.getAllPublicBoards

fetchBoardPublic :: (PublicBoardQuery :> es) => Int -> Eff es (Maybe Board)
fetchBoardPublic = PublicBoardQuery.getPublicBoard

deleteBoard :: (BoardRepo :> es) => DeleteBoardCommand -> Eff es Bool
deleteBoard = BoardRepo.deleteBoard

updateBoard :: (BoardRepo :> es) => UpdateBoardCommand -> Eff es (Maybe Board)
updateBoard = BoardRepo.updateBoard

saveAttachment :: (BoardRepo :> es) => SaveAttachmentCommand -> Eff es (Maybe BoardAttachment)
saveAttachment = BoardRepo.saveAttachment

fetchAttachmentsForBoardPublic :: (PublicBoardQuery :> es) => Int -> Eff es [BoardAttachment]
fetchAttachmentsForBoardPublic = PublicBoardQuery.fetchAttachmentsForBoard
