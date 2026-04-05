{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.UseCase
  ( createBoard,
    fetchAllBoards,
    fetchAllBoardsPublic,
    deleteBoard,
    fetchBoard,
    fetchBoardPublic,
    updateBoard,
    saveAttachment,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..), DeleteBoardCommand (..), SaveAttachmentCommand (..), UpdateBoardCommand (..))
import App.Application.Board.Repository (BoardRepo)
import App.Application.Board.Repository qualified as BoardRepo
import App.Domain.Board.Entity (Board)
import Data.Text qualified as T
import Effectful (Eff, (:>))

data BoardValidationError = TitleEmpty | BodyMarkdownEmpty

createBoard ::
  (BoardRepo :> es) =>
  CreateBoardCommand ->
  Eff es (Either BoardValidationError (Maybe Board))
createBoard cmd = case validateCreate cmd of
  Left e -> return (Left e)
  Right cmd' -> do
    mBoard <- BoardRepo.createBoard cmd'
    return $ Right mBoard

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
  (BoardRepo :> es) =>
  Eff es [Board]
fetchAllBoardsPublic = BoardRepo.getAllPublicBoards

fetchBoard :: (BoardRepo :> es) => Int -> Eff es (Maybe Board)
fetchBoard = BoardRepo.getBoard

fetchBoardPublic :: (BoardRepo :> es) => Int -> Eff es (Maybe Board)
fetchBoardPublic = BoardRepo.getPublicBoard

deleteBoard :: (BoardRepo :> es) => DeleteBoardCommand -> Eff es ()
deleteBoard = BoardRepo.deleteBoard

updateBoard :: (BoardRepo :> es) => UpdateBoardCommand -> Eff es (Maybe Board)
updateBoard = BoardRepo.updateBoard

saveAttachment :: (BoardRepo :> es) => SaveAttachmentCommand -> Eff es ()
saveAttachment = BoardRepo.saveAttachment