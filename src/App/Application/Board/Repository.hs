{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.Repository
  ( createBoard,
    BoardRepo (..),
    getAllBoards,
    getBoard,
    deleteBoard,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..))
import App.Domain.Board.Entity (Board)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data BoardRepo :: Effect where
  CreateBoardOp :: CreateBoardCommand -> BoardRepo m (Maybe Board)
  GetAllBoardsOp :: BoardRepo m [Board]
  GetBoardOp :: Int -> BoardRepo m (Maybe Board)
  DeleteBoardOp :: Int -> BoardRepo m ()

type instance DispatchOf BoardRepo = Dynamic

createBoard :: (BoardRepo :> es) => CreateBoardCommand -> Eff es (Maybe Board)
createBoard op = send (CreateBoardOp op)

getBoard :: (BoardRepo :> es) => Int -> Eff es (Maybe Board)
getBoard boardId = send (GetBoardOp boardId)

getAllBoards :: (BoardRepo :> es) => Eff es [Board]
getAllBoards = send GetAllBoardsOp

deleteBoard :: (BoardRepo :> es) => Int -> Eff es ()
deleteBoard boardId = send (DeleteBoardOp boardId)
