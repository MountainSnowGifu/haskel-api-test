module App.Presentation.SqlServerDemo.Handler
  ( getSqlserverHandler,
    postSqlserverHandler,
  )
where

import App.Application.SqlServerDemo.UseCase (getSqlResult, postSqlResult)
import App.Domain.SqlServerDemo.Entity (unSqlResult)
import App.Infrastructure.DB.Types (MSSQLPool)
import App.Infrastructure.Repository.SqlServerMSSQL (runSqlServerRepoMSSQL)
import Control.Monad.IO.Class (liftIO)
import Effectful (runEff)
import Servant (Handler)

-- | GET /sqlserver ハンドラ
--
--   型の流れ:
--     Eff '[SqlServerRepo, IOE] SqlResult
--       → (runSqlServerRepoMSSQL) → Eff '[IOE] SqlResult
--       → (runEff)                → IO SqlResult
--       → (fmap unSqlResult)      → IO String
--       → (liftIO)                → Handler String
getSqlserverHandler :: MSSQLPool -> Handler String
getSqlserverHandler pool =
  liftIO $ unSqlResult <$> runEff (runSqlServerRepoMSSQL pool getSqlResult)

-- | POST /sqlserver ハンドラ
postSqlserverHandler :: MSSQLPool -> Handler String
postSqlserverHandler pool =
  liftIO $ unSqlResult <$> runEff (runSqlServerRepoMSSQL pool postSqlResult)
