module App.Application.Auth.Principal
  ( AuthPrincipal (..),
  )
where

import App.Domain.Auth.Entity (UserId)

newtype AuthPrincipal = AuthPrincipal
  { principalUserId :: UserId
  }
  deriving (Show, Eq)
