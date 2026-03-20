module App.Domain.Auth.Entity
  ( Username (..),
    Password (..),
    Token (..),
    UserId (..),
    User (..),
  )
where

import qualified Data.Text as T

-- | ユーザー名（プリミティブ型を newtype で包んで型安全にする）
newtype Username = Username {unUsername :: T.Text}
  deriving (Show, Eq, Ord)

-- | パスワード（T.Text と区別できる独立した型）
newtype Password = Password {unPassword :: T.Text}
  deriving (Show, Eq)

-- | 認証トークン（UUID 文字列）
newtype Token = Token {unToken :: T.Text}
  deriving (Show, Eq)

-- | ユーザー ID（Int と区別できる独立した型）
newtype UserId = UserId {unUserId :: Int}
  deriving (Show, Eq, Ord)

-- | 認証ユーザーのドメインエンティティ
--
--   サイト情報（旧 UserStore の site フィールド）は
--   認証ドメインの責務外なので含めない
data User = User
  { userUsername :: Username,
    userPassword :: Password,
    userUserId :: UserId
  }
  deriving (Show, Eq)
