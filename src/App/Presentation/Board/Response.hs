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
import Data.Text (Text, pack)
import Data.Time (defaultTimeLocale, formatTime)
import GHC.Generics (Generic)

data CreatedBoardResponse = CreatedBoardResponse
  { boardId :: Int,
    createdBoardMessage :: Text,
    boardCategory :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON CreatedBoardResponse

instance ToJSON CreatedBoardResponse

toCreatedBoardResponse :: Board -> CreatedBoardResponse
toCreatedBoardResponse Board {boardId = bid, boardCategory = category} =
  CreatedBoardResponse
    { boardId = bid,
      createdBoardMessage = "Board created successfully.",
      boardCategory = category
    }

data BoardResponse = BoardResponse
  { boardId :: Int,
    title :: Text,
    bodyMarkdown :: Text,
    authorId :: Int,
    boardCategory :: Text,
    createdAt :: Text,
    updatedAt :: Text,
    attachments :: [AttachmentResponse]
  }
  deriving (Show, Eq, Generic)

instance FromJSON BoardResponse

instance ToJSON BoardResponse

toBoardResponse :: BoardWithAttachments -> BoardResponse
toBoardResponse BoardWithAttachments {board = Board {boardId = bid, boardTitle = t, boardBodyMarkdown = bm, boardAuthorId = aid, boardCategory = category, boardCreatedAt = cat, boardUpdatedAt = uat}, attachments = atts} =
  BoardResponse
    { boardId = bid,
      title = t,
      bodyMarkdown = bm,
      authorId = aid,
      boardCategory = category,
      createdAt = pack (formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" cat),
      updatedAt = pack (formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" uat),
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