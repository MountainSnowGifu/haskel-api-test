{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}

module App.Presentation.Board.Request
  ( PostBoardRequest (..),
    toCreateBoardCommand,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

data PostBoardRequest = PostBoardRequest
  { boardTitle :: Text,
    boardBodyMarkdown :: Text
  }
  deriving (Show, Eq, Generic)

instance FromJSON PostBoardRequest

instance ToJSON PostBoardRequest

toCreateBoardCommand :: PostBoardRequest -> CreateBoardCommand
toCreateBoardCommand PostBoardRequest {..} =
  CreateBoardCommand
    { cmdBoardTitle = boardTitle,
      cmdBoardBodyMarkdown = boardBodyMarkdown
    }