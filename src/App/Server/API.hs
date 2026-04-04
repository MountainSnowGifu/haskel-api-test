{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Server.API
  ( API,
    combinedAPI,
  )
where

import App.Application.Auth.Principal (AuthPrincipal)
import App.Presentation.Auth.API (AuthAPI)
import App.Presentation.Board.API (BoardAPI)
import App.Presentation.BudgetTracker.API (BudgetTrackerAPI)
import App.Presentation.Chat.API (ChatAPI)
import App.Presentation.HabitTracker.API (HabitTrackerAPI)
import App.Presentation.Task.API (TaskAPI)
import Servant
import Servant.Server.Experimental.Auth (AuthServerData)

-- | AuthProtect "token-auth" が解決する値の型を宣言する
--
-- これにより Servant は AuthHandler Request AuthPrincipal を
-- Context から探してハンドラに渡すことができる。
type instance AuthServerData (AuthProtect "token-auth") = AuthPrincipal

type API = AuthAPI :<|> TaskAPI :<|> ChatAPI :<|> BudgetTrackerAPI :<|> HabitTrackerAPI :<|> BoardAPI :<|> "uploads" :> Raw

combinedAPI :: Proxy API
combinedAPI = Proxy
