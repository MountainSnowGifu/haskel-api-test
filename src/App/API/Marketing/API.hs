{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.API.Marketing.API
  ( MarketingAPI,
  )
where

import App.API.Marketing.Types (ClientInfo, Email)
import Servant

type MarketingAPI =
  "marketing" :> ReqBody '[JSON] ClientInfo :> Post '[JSON] Email
