{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Board.Response
  ( CreatedBoardResponse (..),
    toCreatedBoardResponse,
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
