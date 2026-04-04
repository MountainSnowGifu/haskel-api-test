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
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Application.Board.Command (DeleteBoardCommand (..))
import App.Application.Board.Repository (BoardRepo)
import App.Application.Board.UseCase (createBoard, deleteBoard, fetchAllBoards, fetchBoard)
import App.Presentation.Board.Request (PostBoardRequest, toCreateBoardCommand)
import App.Presentation.Board.Response
  ( BoardResponse (..),
    CreatedBoardResponse (..),
    toBoardResponse,
    toCreatedBoardResponse,
  )
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
  boards <- liftIO $ mkRun user fetchAllBoards
  return (map toBoardResponse boards)

deleteBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> Handler NoContent
deleteBoardHandler mkRun user hid = do
  liftIO $ mkRun user (deleteBoard (DeleteBoardCommand hid))
  return NoContent

getBoardHandler :: (AuthPrincipal -> BoardRunner) -> AuthPrincipal -> Int -> Handler BoardResponse
getBoardHandler mkRun user bid = do
  result <- liftIO $ mkRun user (fetchBoard bid)
  case result of
    Nothing -> throwError err404
    Just board -> return (toBoardResponse board)
