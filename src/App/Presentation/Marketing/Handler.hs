module App.Presentation.Marketing.Handler
  ( marketing,
  )
where

import App.Application.Marketing.UseCase (createEmail)
import App.Domain.Marketing.Entity (ClientInfo, Email)
import Servant (Handler)

-- | POST /marketing ハンドラ
--
--   型の流れ:
--     ClientInfo → createEmail → Email → Handler Email
marketing :: ClientInfo -> Handler Email
marketing = return . createEmail
