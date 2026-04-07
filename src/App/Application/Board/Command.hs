{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Board.Command
  ( CreateBoardCommand (..),
    DeleteBoardCommand (..),
    UpdateBoardCommand (..),
    SaveAttachmentCommand (..),
    DeleteAttachmentCommand (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data CreateBoardCommand = CreateBoardCommand
  { cmdBoardTitle :: Text,
    cmdBoardBodyMarkdown :: Text,
    cmdBoardCategory :: Text
  }
  deriving (Show, Eq, Generic)

newtype DeleteBoardCommand = DeleteBoardCommand {cmdDeleteBoardId :: Int}
  deriving (Show, Eq, Generic)

data UpdateBoardCommand = UpdateBoardCommand
  { cmdBoardId :: Int,
    cmdBoardTitle :: Text,
    cmdBoardBodyMarkdown :: Text,
    cmdBoardCategory :: Text
  }
  deriving (Show, Eq, Generic)

data SaveAttachmentCommand = SaveAttachmentCommand
  { cmdBoardId :: Int,
    cmdAttachmentId :: Text,
    cmdAttachmentUrl :: Text
  }
  deriving (Show, Eq, Generic)

data DeleteAttachmentCommand = DeleteAttachmentCommand
  { cmdBoardId :: Int,
    cmdAttachmentId :: Text
  }
  deriving (Show, Eq, Generic)