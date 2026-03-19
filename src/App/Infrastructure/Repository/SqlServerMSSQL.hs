{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.SqlServerMSSQL
  ( runSqlServerRepoMSSQL,
  )
where

import App.Domain.SqlServerDemo.Entity (SqlResult (..))
import App.Domain.SqlServerDemo.Repository (SqlServerRepo (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Database.MSSQLServer.Query (Only (..), sql)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | SqlServerRepo エフェクトを MSSQL で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es              -- IO を実行できるエフェクトが必要
--     => MSSQLPool           -- コネクションプール
--     -> Eff (SqlServerRepo : es) a   -- SqlServerRepo を含むスタック
--     -> Eff es a                     -- SqlServerRepo を除いたスタック
runSqlServerRepoMSSQL ::
  (IOE :> es) =>
  MSSQLPool ->
  Eff (SqlServerRepo : es) a ->
  Eff es a
runSqlServerRepoMSSQL pool = interpret $ \_ -> \case
  GetDemo ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
      print i
      return $ SqlResult "SQL Server message"
  PostDemo ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      [Only i] <- sql conn "SELECT 2 + 2" :: IO [Only Int]
      print i
      return $ SqlResult "SQL Server message"
