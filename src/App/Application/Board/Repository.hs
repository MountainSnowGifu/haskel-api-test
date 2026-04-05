{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.Repository
  ( createBoard,
    BoardRepo (..),
    getAllBoards,
    getAllPublicBoards,
    getBoard,
    getPublicBoard,
    deleteBoard,
    updateBoard,
    saveAttachment,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..), DeleteBoardCommand (..), SaveAttachmentCommand (..), UpdateBoardCommand (..))
import App.Domain.Board.Entity (Board, BoardAttachment)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data BoardRepo :: Effect where
  CreateBoardOp :: CreateBoardCommand -> BoardRepo m (Maybe Board)
  GetAllBoardsOp :: BoardRepo m [Board]
  GetAllPublicBoardsOp :: BoardRepo m [Board]
  GetBoardOp :: Int -> BoardRepo m (Maybe Board)
  GetPublicBoardOp :: Int -> BoardRepo m (Maybe Board)
  DeleteBoardOp :: Int -> BoardRepo m Bool
  UpdateBoardOp :: UpdateBoardCommand -> BoardRepo m (Maybe Board)
  SaveAttachmentOp :: SaveAttachmentCommand -> BoardRepo m (Maybe BoardAttachment)

type instance DispatchOf BoardRepo = Dynamic

createBoard :: (BoardRepo :> es) => CreateBoardCommand -> Eff es (Maybe Board)
createBoard op = send (CreateBoardOp op)

getBoard :: (BoardRepo :> es) => Int -> Eff es (Maybe Board)
getBoard boardId = send (GetBoardOp boardId)

getPublicBoard :: (BoardRepo :> es) => Int -> Eff es (Maybe Board)
getPublicBoard boardId = send (GetPublicBoardOp boardId)

getAllBoards :: (BoardRepo :> es) => Eff es [Board]
getAllBoards = send GetAllBoardsOp

getAllPublicBoards :: (BoardRepo :> es) => Eff es [Board]
getAllPublicBoards = send GetAllPublicBoardsOp

deleteBoard :: (BoardRepo :> es) => DeleteBoardCommand -> Eff es Bool
deleteBoard (DeleteBoardCommand bid) = send (DeleteBoardOp bid)

updateBoard :: (BoardRepo :> es) => UpdateBoardCommand -> Eff es (Maybe Board)
updateBoard cmd = send (UpdateBoardOp cmd)

saveAttachment :: (BoardRepo :> es) => SaveAttachmentCommand -> Eff es (Maybe BoardAttachment)
saveAttachment cmd = send (SaveAttachmentOp cmd)