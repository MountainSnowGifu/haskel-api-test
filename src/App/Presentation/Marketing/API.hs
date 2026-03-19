{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Marketing.API
  ( MarketingAPI,
  )
where

import App.Domain.Marketing.Entity (ClientInfo, Email)
import Servant

type MarketingAPI =
  "marketing" :> ReqBody '[JSON] ClientInfo :> Post '[JSON] Email
