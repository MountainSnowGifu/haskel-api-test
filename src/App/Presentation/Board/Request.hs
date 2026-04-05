{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}

module App.Presentation.Board.Request
  ( PostBoardRequest (..),
    toCreateBoardCommand,
    toUpdateBoardCommand,
    PutBoardRequest (..),
  )
where

import App.Application.Board.Command (CreateBoardCommand (..), UpdateBoardCommand (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

data PostBoardRequest = PostBoardRequest
  { boardTitle :: Text,
    boardBodyMarkdown :: Text,
    boardCategory :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PostBoardRequest

instance ToJSON PostBoardRequest

toCreateBoardCommand :: PostBoardRequest -> CreateBoardCommand
toCreateBoardCommand PostBoardRequest {..} =
  CreateBoardCommand
    { cmdBoardTitle = boardTitle,
      cmdBoardBodyMarkdown = boardBodyMarkdown,
      cmdBoardCategory = boardCategory
    }

data PutBoardRequest = PutBoardRequest
  { putBoardTitle :: Text,
    putBoardBodyMarkdown :: Text,
    putBoardCategory :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PutBoardRequest

instance ToJSON PutBoardRequest

toUpdateBoardCommand :: Int -> PutBoardRequest -> UpdateBoardCommand
toUpdateBoardCommand boardId PutBoardRequest {..} =
  UpdateBoardCommand
    { cmdBoardId = boardId,
      cmdBoardTitle = putBoardTitle,
      cmdBoardBodyMarkdown = putBoardBodyMarkdown,
      cmdBoardCategory = putBoardCategory
    }