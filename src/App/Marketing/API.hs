{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Marketing.API
  ( MarketingAPI,
  )
where

import App.Marketing.Types (ClientInfo, Email)
import Servant

type MarketingAPI =
  "marketing" :> ReqBody '[JSON] ClientInfo :> Post '[JSON] Email
