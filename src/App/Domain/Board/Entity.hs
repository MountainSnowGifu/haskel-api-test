{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.Board.Entity (Board (..), BoardAttachment (..), BoardWithAttachments (..), BoardCategory (..)) where

import App.Domain.Board.ValueObject
  ( AttachmentFileName,
    AttachmentId,
    AttachmentUrl,
    BoardAuthorId,
    BoardBodyMarkdown,
    BoardCategoryId,
    BoardCategoryName,
    BoardCategoryText,
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
    boardCategory :: BoardCategoryText,
    boardCreatedAt :: BoardCreatedAt,
    boardUpdatedAt :: BoardUpdatedAt
  }
  deriving (Show, Eq, Generic)

data BoardAttachment = BoardAttachment
  { boardId :: BoardId,
    attachmentId :: AttachmentId,
    attachmentUrl :: AttachmentUrl,
    attachmentFileName :: AttachmentFileName
  }
  deriving (Show, Eq, Generic)

data BoardWithAttachments = BoardWithAttachments
  { board :: Board,
    attachments :: [BoardAttachment]
  }
  deriving (Show, Eq, Generic)

data BoardCategory = BoardCategory
  { boardCategoryId :: BoardCategoryId,
    boardCategoryName :: BoardCategoryName
  }
  deriving (Show, Eq, Generic)