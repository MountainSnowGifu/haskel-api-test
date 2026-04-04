{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.Repository
  ( createBoard,
    BoardRepo (..),
    getAllBoard,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..))
import App.Domain.Board.Entity (Board)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data BoardRepo :: Effect where
  CreateBoardOp :: CreateBoardCommand -> BoardRepo m (Maybe Board)
  GetAllBoardOp :: BoardRepo m (Maybe [Board])

type instance DispatchOf BoardRepo = Dynamic

createBoard :: (BoardRepo :> es) => CreateBoardCommand -> Eff es (Maybe Board)
createBoard op = send (CreateBoardOp op)

getAllBoard :: (BoardRepo :> es) => Eff es (Maybe [Board])
getAllBoard = send GetAllBoardOp