{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Board.Response
  ( CreatedBoardResponse (..),
    toCreatedBoardResponse,
    BoardResponse (..),
    toBoardResponse,
    AttachmentResponse (..),
  )
where

import App.Domain.Board.Entity (Board (..))
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
    bodyMarkdown :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON BoardResponse

instance ToJSON BoardResponse

toBoardResponse :: Board -> BoardResponse
toBoardResponse Board {boardId = bid, boardTitle = t, boardBodyMarkdown = bmd} =
  BoardResponse
    { boardId = bid,
      title = t,
      bodyMarkdown = bmd
    }

data AttachmentResponse = AttachmentResponse
  { attachmentId :: Text,
    attachmentUrl :: Text
  }
  deriving (Show, Eq, Generic)

instance ToJSON AttachmentResponse