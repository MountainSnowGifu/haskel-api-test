{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.Repository
  ( createBoard,
    BoardRepo (..),
    deleteBoard,
    updateBoard,
    saveAttachment,
    deleteAttachment,
  )
where

import App.Application.Board.Command
  ( CreateBoardCommand (..),
    DeleteAttachmentCommand (..),
    DeleteBoardCommand (..),
    SaveAttachmentCommand (..),
    UpdateBoardCommand (..),
  )
import App.Domain.Board.Entity (Board, BoardAttachment)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data BoardRepo :: Effect where
  CreateBoardOp :: CreateBoardCommand -> BoardRepo m (Maybe Board)
  DeleteBoardOp :: DeleteBoardCommand -> BoardRepo m Bool
  UpdateBoardOp :: UpdateBoardCommand -> BoardRepo m (Maybe Board)
  SaveAttachmentOp :: SaveAttachmentCommand -> BoardRepo m (Maybe BoardAttachment)
  DeleteAttachmentOp :: DeleteAttachmentCommand -> BoardRepo m (Maybe BoardAttachment)

type instance DispatchOf BoardRepo = Dynamic

createBoard :: (BoardRepo :> es) => CreateBoardCommand -> Eff es (Maybe Board)
createBoard cmd = send (CreateBoardOp cmd)

deleteBoard :: (BoardRepo :> es) => DeleteBoardCommand -> Eff es Bool
deleteBoard cmd = send (DeleteBoardOp cmd)

updateBoard :: (BoardRepo :> es) => UpdateBoardCommand -> Eff es (Maybe Board)
updateBoard cmd = send (UpdateBoardOp cmd)

saveAttachment :: (BoardRepo :> es) => SaveAttachmentCommand -> Eff es (Maybe BoardAttachment)
saveAttachment cmd = send (SaveAttachmentOp cmd)

deleteAttachment :: (BoardRepo :> es) => DeleteAttachmentCommand -> Eff es (Maybe BoardAttachment)
deleteAttachment cmd = send (DeleteAttachmentOp cmd)
