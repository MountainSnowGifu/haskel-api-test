{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.SqlServerDemo.Repository
  ( SqlServerRepo (..),
    getDemo,
    postDemo,
  )
where

import App.Domain.SqlServerDemo.Entity (SqlResult)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | SqlServerRepo エフェクト
--
--   各コンストラクタが「操作」を表す:
--     GetDemo  :: SqlServerRepo m SqlResult  -- GET 用クエリ
--     PostDemo :: SqlServerRepo m SqlResult  -- POST 用クエリ
data SqlServerRepo :: Effect where
  GetDemo :: SqlServerRepo m SqlResult
  PostDemo :: SqlServerRepo m SqlResult

type instance DispatchOf SqlServerRepo = Dynamic

-- | GET 用クエリを実行する
getDemo :: (SqlServerRepo :> es) => Eff es SqlResult
getDemo = send GetDemo

-- | POST 用クエリを実行する
postDemo :: (SqlServerRepo :> es) => Eff es SqlResult
postDemo = send PostDemo
