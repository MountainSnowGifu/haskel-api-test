{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.PublicRepository
  ( PublicBoardQuery (..),
    getAllPublicBoards,
    getPublicBoard,
    getAttachmentsForBoard,
  )
where

import App.Domain.Board.Entity (Board, BoardAttachment)
import App.Domain.Board.ValueObject (BoardId (..))
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | 公開掲示板の読み取り専用クエリ
data PublicBoardQuery :: Effect where
  GetAllPublicBoardsQ :: PublicBoardQuery m [Board]
  GetPublicBoardQ :: BoardId -> PublicBoardQuery m (Maybe Board)
  GetAttachmentsForBoardQ :: BoardId -> PublicBoardQuery m (Maybe [BoardAttachment])

type instance DispatchOf PublicBoardQuery = Dynamic

getAllPublicBoards :: (PublicBoardQuery :> es) => Eff es [Board]
getAllPublicBoards = send GetAllPublicBoardsQ

getPublicBoard :: (PublicBoardQuery :> es) => BoardId -> Eff es (Maybe Board)
getPublicBoard boardId = send (GetPublicBoardQ boardId)

getAttachmentsForBoard :: (PublicBoardQuery :> es) => BoardId -> Eff es (Maybe [BoardAttachment])
getAttachmentsForBoard boardId = send (GetAttachmentsForBoardQ boardId)
