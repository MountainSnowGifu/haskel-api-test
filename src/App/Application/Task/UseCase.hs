{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}

module App.Application.Task.UseCase
  ( getTaskResult,
    postTaskResult,
    getTaskAllResult,
  )
where

import App.Domain.Task.Entity (Task)
import App.Domain.Task.Repository (TaskRepo, getTask, getTaskAll, postTask)
import Effectful

-- | GET 用ユースケース
--
--   型: (TaskRepo :> es) => Eff es Task
--
--   DB の種類（MSSQL/PostgreSQL 等）を知らない。
--   「TaskRepo エフェクトが使える環境」であれば動く。
getTaskResult :: (TaskRepo :> es) => Eff es Task
getTaskResult = getTask

getTaskAllResult :: (TaskRepo :> es) => Eff es [Task]
getTaskAllResult = getTaskAll

-- | POST 用ユースケース
postTaskResult :: (TaskRepo :> es) => Eff es Task
postTaskResult = postTask