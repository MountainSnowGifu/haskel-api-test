module App.Domain.Board.BoardService (createBoardWithAttachments) where

import App.Domain.Board.Entity (Board, BoardAttachment, BoardWithAttachments (..))

createBoardWithAttachments :: Board -> [BoardAttachment] -> BoardWithAttachments
createBoardWithAttachments b atts = BoardWithAttachments {board = b, attachments = atts}