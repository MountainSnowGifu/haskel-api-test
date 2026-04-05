{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Board.PublicRepository
  ( PublicBoardQuery (..),
    getAllPublicBoards,
    getPublicBoard,
    fetchAttachmentsForBoard,
  )
where

import App.Domain.Board.Entity (Board, BoardAttachment)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | 公開掲示板の読み取り専用クエリ
data PublicBoardQuery :: Effect where
  GetAllPublicBoardsQ :: PublicBoardQuery m (Maybe [Board])
  GetPublicBoardQ :: Int -> PublicBoardQuery m (Maybe Board)
  GetAttachmentsForBoardOp :: Int -> PublicBoardQuery m (Maybe [BoardAttachment])

type instance DispatchOf PublicBoardQuery = Dynamic

getAllPublicBoards :: (PublicBoardQuery :> es) => Eff es (Maybe [Board])
getAllPublicBoards = send GetAllPublicBoardsQ

getPublicBoard :: (PublicBoardQuery :> es) => Int -> Eff es (Maybe Board)
getPublicBoard bid = send (GetPublicBoardQ bid)

fetchAttachmentsForBoard :: (PublicBoardQuery :> es) => Int -> Eff es (Maybe [BoardAttachment])
fetchAttachmentsForBoard boardId = send (GetAttachmentsForBoardOp boardId)
