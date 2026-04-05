{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.Repository
  ( createBoard,
    BoardRepo (..),
    getAllBoards,
    deleteBoard,
    updateBoard,
    saveAttachment,
    fetchAttachmentsForBoard,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..), DeleteBoardCommand (..), SaveAttachmentCommand (..), UpdateBoardCommand (..))
import App.Domain.Board.Entity (Board, BoardAttachment)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data BoardRepo :: Effect where
  CreateBoardOp :: CreateBoardCommand -> BoardRepo m (Maybe Board)
  GetAllBoardsOp :: BoardRepo m [Board]
  DeleteBoardOp :: Int -> BoardRepo m Bool
  UpdateBoardOp :: UpdateBoardCommand -> BoardRepo m (Maybe Board)
  SaveAttachmentOp :: SaveAttachmentCommand -> BoardRepo m (Maybe BoardAttachment)
  GetAttachmentsForBoardOp :: Int -> BoardRepo m [BoardAttachment]

type instance DispatchOf BoardRepo = Dynamic

createBoard :: (BoardRepo :> es) => CreateBoardCommand -> Eff es (Maybe Board)
createBoard op = send (CreateBoardOp op)

getAllBoards :: (BoardRepo :> es) => Eff es [Board]
getAllBoards = send GetAllBoardsOp

deleteBoard :: (BoardRepo :> es) => DeleteBoardCommand -> Eff es Bool
deleteBoard (DeleteBoardCommand bid) = send (DeleteBoardOp bid)

updateBoard :: (BoardRepo :> es) => UpdateBoardCommand -> Eff es (Maybe Board)
updateBoard cmd = send (UpdateBoardOp cmd)

saveAttachment :: (BoardRepo :> es) => SaveAttachmentCommand -> Eff es (Maybe BoardAttachment)
saveAttachment cmd = send (SaveAttachmentOp cmd)

fetchAttachmentsForBoard :: (BoardRepo :> es) => Int -> Eff es [BoardAttachment]
fetchAttachmentsForBoard boardId = send (GetAttachmentsForBoardOp boardId)
