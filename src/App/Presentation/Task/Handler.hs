module App.Presentation.Task.Handler
  ( getTaskHandler,
    postTaskHandler,
    getTaskAllHandler,
  )
where

import App.Application.Task.UseCase (getTaskAllResult, getTaskResult, postTaskResult)
import App.Domain.Auth.Entity (User)
import App.Domain.Task.Entity (Task)
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Repository.TaskSQLServer (runTaskRepo)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant (Handler)

-- | GET /task ハンドラ
--
--   AuthProtect "token-auth" により Servant が User を解決して渡す。
--   型の流れ:
--     AuthHandler Request User → User
--       → getTaskHandler pool user
--       → Eff '[TaskRepo, IOE] Task
--       → (runTaskRepo) → Eff '[IOE] Task
--       → (runEff)      → IO Task
--       → (liftIO)      → Handler Task
getTaskHandler :: MSSQLPool -> User -> Handler Task
getTaskHandler pool _user =
  liftIO $ runEff (runTaskRepo pool getTaskResult)

getTaskAllHandler :: MSSQLPool -> User -> Handler [Task]
getTaskAllHandler pool _user =
  liftIO $ runEff (runTaskRepo pool getTaskAllResult)

-- | POST /task ハンドラ
postTaskHandler :: MSSQLPool -> User -> Task -> Handler Task
postTaskHandler pool _user _body =
  liftIO $ runEff (runTaskRepo pool postTaskResult)
