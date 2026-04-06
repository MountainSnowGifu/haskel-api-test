{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.Board.Entity (Board (..), BoardAttachment (..), BoardWithAttachments (..)) where

import App.Domain.Board.ValueObject
  ( AttachmentId,
    AttachmentUrl,
    BoardAuthorId,
    BoardBodyMarkdown,
    BoardCategory,
    BoardCreatedAt,
    BoardId,
    BoardTitle,
    BoardUpdatedAt,
  )
import GHC.Generics (Generic)

data Board = Board
  { boardId :: BoardId,
    boardTitle :: BoardTitle,
    boardBodyMarkdown :: BoardBodyMarkdown,
    boardAuthorId :: BoardAuthorId,
    boardCategory :: BoardCategory,
    boardCreatedAt :: BoardCreatedAt,
    boardUpdatedAt :: BoardUpdatedAt
  }
  deriving (Show, Eq, Generic)

data BoardAttachment = BoardAttachment
  { boardId :: BoardId,
    attachmentId :: AttachmentId,
    attachmentUrl :: AttachmentUrl
  }
  deriving (Show, Eq, Generic)

data BoardWithAttachments = BoardWithAttachments
  { board :: Board,
    attachments :: [BoardAttachment]
  }
  deriving (Show, Eq, Generic)
