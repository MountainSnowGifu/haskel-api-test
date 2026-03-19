{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.SqlServerDemo.API
  ( SqlServerAPI,
  )
where

import Servant

type SqlServerAPI =
  "sqlserver" :> Get '[PlainText] String
    :<|> "sqlserver" :> Post '[PlainText] String
