{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App.Application.Board.Command
  ( CreateBoardCommand (..),
  )
where

import Data.Text (Text)
import GHC.Generics (Generic)

data CreateBoardCommand = CreateBoardCommand
  { cmdBoardTitle :: Text,
    cmdBoardBodyMarkdown :: Text
  }
  deriving (Show, Eq, Generic)