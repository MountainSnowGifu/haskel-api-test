module App.DB
  ( MSSQLPool,
    createMSSQLPool,
    withMSSQLConn,
  )
where

import App.DB.SqlserverPool (createMSSQLPool, withMSSQLConn)
import App.DB.Types (MSSQLPool)
