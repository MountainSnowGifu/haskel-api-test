{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Server.API
  ( API,
    combinedAPI,
  )
where

import App.Domain.Auth.Entity (User)
import App.Presentation.Auth.API (LoginAPI)
import App.Presentation.BudgetTracker.API (BudgetTrackerAPI)
import App.Presentation.Chat.API (ChatAPI)
import App.Presentation.Task.API (TaskAPI)
import Servant
import Servant.Server.Experimental.Auth (AuthServerData)

-- | AuthProtect "token-auth" が解決する値の型を宣言する
--
-- これにより Servant は AuthHandler Request User を
-- Context から探してハンドラに渡すことができる。
type instance AuthServerData (AuthProtect "token-auth") = User

type API = LoginAPI :<|> TaskAPI :<|> ChatAPI :<|> BudgetTrackerAPI

combinedAPI :: Proxy API
combinedAPI = Proxy
