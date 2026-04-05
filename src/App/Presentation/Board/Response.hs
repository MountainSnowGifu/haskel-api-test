{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Board.Response
  ( CreatedBoardResponse (..),
    toCreatedBoardResponse,
    BoardResponse (..),
    toBoardResponse,
    AttachmentResponse (..),
    toAttachmentResponse,
  )
where

import App.Domain.Board.Entity (Board (..), BoardAttachment (..), BoardWithAttachments (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

data CreatedBoardResponse = CreatedBoardResponse
  { boardId :: Int,
    createdBoardMessage :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON CreatedBoardResponse

instance ToJSON CreatedBoardResponse

toCreatedBoardResponse :: Board -> CreatedBoardResponse
toCreatedBoardResponse Board {boardId = bid} =
  CreatedBoardResponse
    { boardId = bid,
      createdBoardMessage = "Board created successfully."
    }

data BoardResponse = BoardResponse
  { boardId :: Int,
    title :: Text,
    bodyMarkdown :: Text,
    authorId :: Int,
    attachments :: [AttachmentResponse]
  }
  deriving (Show, Eq, Generic)

instance FromJSON BoardResponse

instance ToJSON BoardResponse

toBoardResponse :: BoardWithAttachments -> BoardResponse
toBoardResponse BoardWithAttachments {board = Board {boardId = bid, boardTitle = t, boardBodyMarkdown = bm, boardAuthorId = aid}, attachments = atts} =
  BoardResponse
    { boardId = bid,
      title = t,
      bodyMarkdown = bm,
      authorId = aid,
      attachments = map toAttachmentResponse atts
    }

data AttachmentResponse = AttachmentResponse
  { boardId :: Int,
    attachmentId :: Text,
    attachmentUrl :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON AttachmentResponse

instance ToJSON AttachmentResponse

toAttachmentResponse :: BoardAttachment -> AttachmentResponse
toAttachmentResponse BoardAttachment {boardId = bid, attachmentId = aid, attachmentUrl = url} =
  AttachmentResponse
    { boardId = bid,
      attachmentId = aid,
      attachmentUrl = url
    }