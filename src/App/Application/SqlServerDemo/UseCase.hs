{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.SqlServerDemo.UseCase
  ( getSqlResult,
    postSqlResult,
  )
where

import App.Domain.SqlServerDemo.Entity (SqlResult)
import App.Domain.SqlServerDemo.Repository (SqlServerRepo, getDemo, postDemo)
import Effectful

-- | GET 用ユースケース
--
--   型: (SqlServerRepo :> es) => Eff es SqlResult
--
--   DB の種類（MSSQL/PostgreSQL 等）を知らない。
--   「SqlServerRepo エフェクトが使える環境」であれば動く。
getSqlResult :: (SqlServerRepo :> es) => Eff es SqlResult
getSqlResult = getDemo

-- | POST 用ユースケース
postSqlResult :: (SqlServerRepo :> es) => Eff es SqlResult
postSqlResult = postDemo
