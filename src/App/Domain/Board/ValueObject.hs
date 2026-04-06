module App.Domain.Board.ValueObject
  ( BoardId (..),
    BoardTitle (..),
    BoardBodyMarkdown (..),
    BoardAuthorId (..),
    BoardCategory (..),
    BoardCreatedAt (..),
    BoardUpdatedAt (..),
    AttachmentId (..),
    AttachmentUrl (..),
    userIdToAuthorId,
  )
where

import App.Domain.Auth.Entity (UserId (..))
import Data.Text (Text)
import Data.Time (UTCTime)

newtype BoardId = BoardId Int
  deriving (Show, Eq, Ord)

newtype BoardTitle = BoardTitle Text
  deriving (Show, Eq, Ord)

newtype BoardBodyMarkdown = BoardBodyMarkdown Text
  deriving (Show, Eq, Ord)

newtype BoardAuthorId = BoardAuthorId Int
  deriving (Show, Eq, Ord)

newtype BoardCategory = BoardCategory Text
  deriving (Show, Eq, Ord)

newtype BoardCreatedAt = BoardCreatedAt UTCTime
  deriving (Show, Eq, Ord)

newtype BoardUpdatedAt = BoardUpdatedAt UTCTime
  deriving (Show, Eq, Ord)

newtype AttachmentId = AttachmentId Text
  deriving (Show, Eq, Ord)

newtype AttachmentUrl = AttachmentUrl Text
  deriving (Show, Eq, Ord)

-- | Auth BC の UserId を Board BC の BoardAuthorId へ変換する。
-- BC 境界をまたぐ参照は ID のみで行うという DDD の原則に従い、
-- 変換の意図をドメイン層で明示する。
userIdToAuthorId :: UserId -> BoardAuthorId
userIdToAuthorId (UserId i) = BoardAuthorId i
