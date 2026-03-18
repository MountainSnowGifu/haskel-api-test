module App.Core.Env
  ( AppM,
    nt,
  )
where

import App.Core.Config (Config)
import Control.Monad.Reader (ReaderT, runReaderT)
import Servant (Handler)

-- カスタムモナド: Config を環境として持つ ReaderT
type AppM = ReaderT Config Handler

-- AppM を Handler に変換する自然変換
nt :: Config -> AppM a -> Handler a
nt config action = runReaderT action config
