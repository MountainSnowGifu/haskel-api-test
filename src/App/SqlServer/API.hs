{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.SqlServer.API
  ( SqlServerAPI,
  )
where

import Servant

type SqlServerAPI =
  "sqlserver" :> Get '[PlainText] String
    :<|> "sqlserver" :> Post '[PlainText] String
