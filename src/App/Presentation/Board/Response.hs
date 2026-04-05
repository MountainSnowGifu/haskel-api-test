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

import App.Domain.Board.Entity (Board (..), BoardAttachment (..))
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
    authorId :: Int
  }
  deriving (Show, Eq, Generic)

instance FromJSON BoardResponse

instance ToJSON BoardResponse

toBoardResponse :: Board -> BoardResponse
toBoardResponse Board {boardId = bid, boardTitle = t, boardBodyMarkdown = bmd, boardAuthorId = aid} =
  BoardResponse
    { boardId = bid,
      title = t,
      bodyMarkdown = bmd,
      authorId = aid
    }

data AttachmentResponse = AttachmentResponse
  { boardId :: Int,
    attachmentId :: Text,
    attachmentUrl :: Text
  }
  deriving (Show, Eq, Generic)

instance ToJSON AttachmentResponse

toAttachmentResponse :: BoardAttachment -> AttachmentResponse
toAttachmentResponse BoardAttachment {boardId = bid, attachmentId = aid, attachmentUrl = url} =
  AttachmentResponse
    { boardId = bid,
      attachmentId = aid,
      attachmentUrl = url
    }