module App.Application.Auth.Principal
  ( AuthPrincipal (..),
  )
where

import App.Domain.Auth.Entity (Token, UserId)

data AuthPrincipal = AuthPrincipal
  { principalUserId :: UserId,
    principalToken :: Token
  }
  deriving (Show, Eq)
