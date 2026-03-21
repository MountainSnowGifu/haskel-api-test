{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Task.API
  ( TaskAPI,
  )
where

import App.Presentation.Task.Request (PatchTaskRequest, PostTaskRequest, UpdateTaskRequest)
import App.Presentation.Task.Response (DeleteTaskResponse, PatchTaskResponse, TaskResponse)
import Servant

type TaskAPI =
  AuthProtect "token-auth" :> "task" :> Capture "taskId" Int :> Get '[JSON] TaskResponse
    :<|> AuthProtect "token-auth" :> "task-all" :> Get '[JSON] [TaskResponse]
    :<|> AuthProtect "token-auth" :> "task" :> ReqBody '[JSON] PostTaskRequest :> Post '[JSON] TaskResponse
    :<|> AuthProtect "token-auth" :> "task" :> Capture "taskId" Int :> ReqBody '[JSON] UpdateTaskRequest :> Put '[JSON] TaskResponse
    :<|> AuthProtect "token-auth" :> "task" :> Capture "taskId" Int :> ReqBody '[JSON] PatchTaskRequest :> Patch '[JSON] PatchTaskResponse
    :<|> AuthProtect "token-auth" :> "task" :> Capture "taskId" Int :> Delete '[JSON] DeleteTaskResponse
