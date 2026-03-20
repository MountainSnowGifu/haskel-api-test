{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.Task.Repository
  ( TaskRepo (..),
    getTask,
    postTask,
    getTaskAll,
  )
where

import App.Domain.Task.Entity (Task)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data TaskRepo :: Effect where
  GetTask :: TaskRepo m Task
  GetTaskAll :: TaskRepo m [Task]
  PostTask :: TaskRepo m Task

type instance DispatchOf TaskRepo = Dynamic

-- | GET 用クエリを実行する
getTask :: (TaskRepo :> es) => Eff es Task
getTask = send GetTask

-- | GET 用クエリを実行する
getTaskAll :: (TaskRepo :> es) => Eff es [Task]
getTaskAll = send GetTaskAll

-- | POST 用クエリを実行する
postTask :: (TaskRepo :> es) => Eff es Task
postTask = send PostTask
