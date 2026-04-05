{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.Board.Entity (Board (..), BoardAttachment (..), BoardWithAttachments (..)) where

import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

data Board = Board
  { boardId :: Int,
    boardTitle :: Text,
    boardBodyMarkdown :: Text,
    boardAuthorId :: Int,
    boardCategory :: Text,
    boardCreatedAt :: UTCTime,
    boardUpdatedAt :: UTCTime
  }
  deriving (Show, Eq, Generic)

data BoardAttachment = BoardAttachment
  { boardId :: Int,
    attachmentId :: Text,
    attachmentUrl :: Text
  }
  deriving (Show, Eq, Generic)

data BoardWithAttachments = BoardWithAttachments
  { board :: Board,
    attachments :: [BoardAttachment]
  }
  deriving (Show, Eq, Generic)
