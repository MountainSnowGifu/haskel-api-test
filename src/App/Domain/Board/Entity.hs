{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Domain.Board.Entity (Board (..)) where

import Data.Text (Text)
import GHC.Generics (Generic)

data Board = Board
  { boardId :: Int,
    boardTitle :: Text,
    boardBodyMarkdown :: Text
  }
  deriving (Show, Eq, Generic)
