{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Task.API
  ( TaskAPI,
  )
where

import App.Domain.Task.Entity (Task)
import Servant

type TaskAPI =
  AuthProtect "token-auth" :> "task" :> Get '[JSON] Task
    :<|> AuthProtect "token-auth" :> "task-all" :> Get '[JSON] [Task]
    :<|> AuthProtect "token-auth" :> "task" :> ReqBody '[JSON] Task :> Post '[JSON] Task