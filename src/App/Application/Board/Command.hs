{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Board.Command
  ( CreateBoardCommand (..),
    DeleteBoardCommand (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data CreateBoardCommand = CreateBoardCommand
  { cmdBoardTitle :: Text,
    cmdBoardBodyMarkdown :: Text
  }
  deriving (Show, Eq, Generic)

newtype DeleteBoardCommand = DeleteBoardCommand {cmdDeleteBoardId :: Int}
  deriving (Show, Eq, Generic)