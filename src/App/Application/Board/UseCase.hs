{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.UseCase
  ( createBoard,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..))
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
validateCreate cmd
  | T.null (cmdBoardTitle cmd) = Left TitleEmpty
  | T.null (cmdBoardBodyMarkdown cmd) = Left BodyMarkdownEmpty
  | otherwise = Right cmd