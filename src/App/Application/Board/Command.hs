{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Board.Command
  ( CreateBoardCommand (..),
    DeleteBoardCommand (..),
    UpdateBoardCommand (..),
    SaveAttachmentCommand (..),
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

data UpdateBoardCommand = UpdateBoardCommand
  { cmdBoardId :: Int,
    cmdBoardTitle :: Text,
    cmdBoardBodyMarkdown :: Text
  }
  deriving (Show, Eq, Generic)

data SaveAttachmentCommand = SaveAttachmentCommand
  { cmdAttachmentId :: Text,
    cmdAttachmentUrl :: Text
  }
  deriving (Show, Eq, Generic)