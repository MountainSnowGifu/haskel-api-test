{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Task.APISpec (spec) where

import App.Application.Auth.Principal (AuthPrincipal (..))
import App.Application.Task.Command
  ( CreateTaskCommand (..),
    PatchTaskCommand (..),
    TaskStatusChanged (..),
    UpdateTaskCommand (..),
  )
import App.Application.Task.Repository (TaskRepo (..))
import App.Domain.Auth.Entity (Token (..), UserId (..))
import App.Domain.Task.Entity (Task (..), TaskPriority (..), TaskStatus (..))
import App.Presentation.Task.API (TaskAPI)
import App.Presentation.Task.Handler
import App.Server.API ()
import Data.Aeson (encode, object, (.=))
import Data.IORef
import Data.List (find)
import Data.Text (Text)
import Effectful (Eff, IOE, runEff)
import qualified Effectful as Eff
import Effectful.Dispatch.Dynamic (interpret)
import Network.HTTP.Types (methodDelete, methodPatch, methodPost, methodPut)
import Network.Wai (Request)
import Servant
import Servant.Server.Experimental.Auth (AuthHandler, mkAuthHandler)
import Test.Hspec
import Test.Hspec.Wai

-- ─────────────────────────────────────────────
-- stub: 認証は常に userId=1 で成功させる
-- ─────────────────────────────────────────────

stubAuthHandler :: AuthHandler Request AuthPrincipal
stubAuthHandler = mkAuthHandler $ \_req ->
  return $ AuthPrincipal (UserId 1) (Token "test-token")

-- ─────────────────────────────────────────────
-- fake: IORef でタスク一覧を管理するインタープリタ
--
-- 型:
--   IOE :> es  ← liftIO を使うために必要
--   IORef [Task] ← テスト用のインメモリストレージ
--   Eff (TaskRepo : es) a → Eff es a
-- ─────────────────────────────────────────────

runFakeTaskRepo :: (IOE Eff.:> es) => IORef [Task] -> Eff (TaskRepo ': es) a -> Eff es a
runFakeTaskRepo ref = interpret $ \_ -> \case
  GetTaskOp tid -> do
    tasks <- liftIO $ readIORef ref
    return $ find (\t -> taskId t == tid) tasks
  GetTasksOp ->
    liftIO $ readIORef ref
  CreateTaskOp (CreateTaskCommand tTitle tDesc tStatus tPriority tDueDate) createdAt updatedAt -> do
    tasks <- liftIO $ readIORef ref
    let newId = length tasks + 1
        task = Task newId 1 tTitle tDesc tStatus tPriority tDueDate createdAt updatedAt
    liftIO $ modifyIORef ref (++ [task])
    return task
  ReplaceTaskOp tid (UpdateTaskCommand uTitle uDesc uStatus uPriority uDueDate) -> do
    tasks <- liftIO $ readIORef ref
    case find (\t -> taskId t == tid) tasks of
      Nothing -> return Nothing
      Just old -> do
        let updated =
              old
                { taskTitle = uTitle,
                  taskDescription = uDesc,
                  taskStatus = uStatus,
                  taskPriority = uPriority,
                  taskDueDate = uDueDate
                }
            newTasks = map (\t -> if taskId t == tid then updated else t) tasks
        liftIO $ writeIORef ref newTasks
        return (Just updated)
  ChangeTaskStatusOp tid (PatchTaskCommand pStatus) -> do
    tasks <- liftIO $ readIORef ref
    case find (\t -> taskId t == tid) tasks of
      Nothing -> return Nothing
      Just _ -> do
        liftIO $ modifyIORef ref (map (\t -> if taskId t == tid then t {taskStatus = pStatus} else t))
        return $ Just (TaskStatusChanged tid pStatus "2026-04-06T00:00:00Z")
  DeleteTaskOp tid -> do
    tasks <- liftIO $ readIORef ref
    case find (\t -> taskId t == tid) tasks of
      Nothing -> return Nothing
      Just _ -> do
        liftIO $ modifyIORef ref (filter (\t -> taskId t /= tid))
        return (Just ())

-- ─────────────────────────────────────────────
-- テスト用 Application を組み立てる
-- ─────────────────────────────────────────────

fakeTaskRunner :: IORef [Task] -> AuthPrincipal -> TaskRunner
fakeTaskRunner ref _ eff = runEff $ runFakeTaskRepo ref eff

testApp :: IORef [Task] -> Application
testApp ref =
  let mkRunner = fakeTaskRunner ref
      handlers =
        getTaskHandler mkRunner
          :<|> getTaskAllHandler mkRunner
          :<|> postTaskHandler mkRunner
          :<|> putTaskHandler mkRunner
          :<|> patchTaskHandler mkRunner
          :<|> deleteTaskHandler mkRunner
   in serveWithContext
        (Proxy :: Proxy TaskAPI)
        (stubAuthHandler :. EmptyContext)
        handlers

-- ─────────────────────────────────────────────
-- テストデータ
-- ─────────────────────────────────────────────

sampleTask :: Task
sampleTask =
  Task
    { taskId = 1,
      taskUserId = 1,
      taskTitle = "買い物",
      taskDescription = "",
      taskStatus = Todo,
      taskPriority = High,
      taskDueDate = "2026-04-10",
      taskCreatedAt = "2026-04-01",
      taskUpdatedAt = "2026-04-01"
    }

-- around を使い、各テストケースで独立した IORef を生成する
-- hspec-wai 0.11 は WaiSession st a と状態型があるため
-- ActionWith a の a = (st, Application) = ((), Application)
withFreshApp :: SpecWith ((), Application) -> Spec
withFreshApp = around $ \test -> do
  ref <- newIORef [sampleTask]
  test ((), testApp ref)

-- ─────────────────────────────────────────────
-- テスト本体
-- ─────────────────────────────────────────────

spec :: Spec
spec = withFreshApp $ do
  describe "GET /task/:id" $ do
    it "存在する taskId で 200 を返す" $
      get "/task/1" `shouldRespondWith` 200

    it "存在しない taskId で 404 を返す" $
      get "/task/999" `shouldRespondWith` 404

  describe "GET /task-all" $ do
    it "200 とタスクリストを返す" $
      get "/task-all" `shouldRespondWith` 200

  describe "POST /task" $ do
    it "正常なリクエストで 200 とタスクを返す" $ do
      let body =
            encode $
              object
                [ "taskTitle" .= ("新しいタスク" :: Text),
                  "taskDescription" .= ("" :: Text),
                  "taskStatus" .= ("Todo" :: Text),
                  "taskPriority" .= ("Medium" :: Text),
                  "taskDueDate" .= ("2026-05-01" :: Text)
                ]
      request methodPost "/task" [("Content-Type", "application/json")] body
        `shouldRespondWith` 200

    it "タイトルが空のとき 400 を返す" $ do
      let body =
            encode $
              object
                [ "taskTitle" .= ("" :: Text),
                  "taskDescription" .= ("" :: Text),
                  "taskStatus" .= ("Todo" :: Text),
                  "taskPriority" .= ("Medium" :: Text),
                  "taskDueDate" .= ("2026-05-01" :: Text)
                ]
      request methodPost "/task" [("Content-Type", "application/json")] body
        `shouldRespondWith` 400

  describe "PUT /task/:id" $ do
    it "存在する taskId で 200 を返す" $ do
      let body =
            encode $
              object
                [ "taskTitle" .= ("更新後タスク" :: Text),
                  "taskDescription" .= ("説明" :: Text),
                  "taskStatus" .= ("InProgress" :: Text),
                  "taskPriority" .= ("Low" :: Text),
                  "taskDueDate" .= ("2026-04-20" :: Text)
                ]
      request methodPut "/task/1" [("Content-Type", "application/json")] body
        `shouldRespondWith` 200

    it "存在しない taskId で 404 を返す" $ do
      let body =
            encode $
              object
                [ "taskTitle" .= ("x" :: Text),
                  "taskDescription" .= ("" :: Text),
                  "taskStatus" .= ("Todo" :: Text),
                  "taskPriority" .= ("Medium" :: Text),
                  "taskDueDate" .= ("2026-05-01" :: Text)
                ]
      request methodPut "/task/999" [("Content-Type", "application/json")] body
        `shouldRespondWith` 404

  describe "PATCH /task/:id" $ do
    it "存在する taskId で 200 を返す" $ do
      let body = encode $ object ["status" .= ("Done" :: Text)]
      request methodPatch "/task/1" [("Content-Type", "application/json")] body
        `shouldRespondWith` 200

    it "存在しない taskId で 404 を返す" $ do
      let body = encode $ object ["status" .= ("Done" :: Text)]
      request methodPatch "/task/999" [("Content-Type", "application/json")] body
        `shouldRespondWith` 404

  describe "DELETE /task/:id" $ do
    it "存在する taskId で 200 を返す" $
      request methodDelete "/task/1" [] "" `shouldRespondWith` 200

    it "存在しない taskId で 404 を返す" $
      request methodDelete "/task/999" [] "" `shouldRespondWith` 404
