{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module App.Presentation.Board.Handler
  ( postBoardHandler,
    BoardRunner,
    getBoardsHandler,
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.Board.Repository (BoardRepo)
import App.Application.Board.UseCase (createBoard, getAllBoard)
import App.Presentation.Board.Request (PostBoardRequest, toCreateBoardCommand)
import App.Presentation.Board.Response (BoardResponse (..), CreatedBoardResponse (..), toBoardResponse, toCreatedBoardResponse)
import Control.Monad.IO.Class (liftIO)
import Effectful (Eff, IOE)
import Servant

type BoardRunner = forall a. Eff '[BoardRepo, IOE] a -> IO a

postBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> PostBoardRequest -> Handler CreatedBoardResponse
postBoardHandler mkRun user req = do
  result <- liftIO $ mkRun user (createBoard (toCreateBoardCommand req))
  case result of
    Left _ -> throwError err400 {errBody = "Failed to create board."}
    Right Nothing -> throwError err400 {errBody = "Failed to create board."}
    Right (Just board) -> return (toCreatedBoardResponse board)

getBoardsHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Handler [BoardResponse]
getBoardsHandler mkRun user = do
  result <- liftIO $ mkRun user getAllBoard
  case result of
    Nothing -> throwError err400 {errBody = "Failed to fetch boards."}
    Just boards -> return (map toBoardResponse boards)