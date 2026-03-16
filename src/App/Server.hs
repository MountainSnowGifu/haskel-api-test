module App.Server
  ( runServant,
  )
where

import App.API (API2, combinedAPI)
import App.Config (Config (..))
import App.DB (MSSQLPool)
import App.Server1 (server1)
import App.Server2 (nt, server2)
import App.Server3 (server3)
import App.Server4 (server4)
import Network.Wai.Handler.Warp (run)
import Servant

app :: Config -> String -> MSSQLPool -> Application
app config dbname pool =
  serve combinedAPI $
    server1 :<|> hoistServer (Proxy :: Proxy API2) (nt config) server2 :<|> server3 dbname :<|> server4 pool

runServant :: Config -> String -> MSSQLPool -> IO ()
runServant config dbname pool = run (port config) (app config dbname pool)
