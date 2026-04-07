{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Board.APISpec (spec) where

import App.Application.Auth.Principal (AuthPrincipal (..))
import App.Application.Board.Command
  ( CreateBoardCommand (..),
    DeleteAttachmentCommand (..),
    DeleteBoardCommand (..),
    SaveAttachmentCommand (..),
    UpdateBoardCommand (..),
  )
import App.Application.Board.PublicRepository (PublicBoardQuery (..))
import App.Application.Board.Repository (BoardRepo (..))
import App.Domain.Auth.Entity (Token (..), UserId (..))
import App.Domain.Board.Entity (Board (..), BoardAttachment (..))
import App.Domain.Board.ValueObject
  ( AttachmentId (..),
    AttachmentUrl (..),
    BoardAuthorId (..),
    BoardBodyMarkdown (..),
    BoardCategory (..),
    BoardCreatedAt (..),
    BoardId (..),
    BoardTitle (..),
    BoardUpdatedAt (..),
  )
import App.Presentation.Board.API (BoardAPI)
import App.Presentation.Board.Handler
  ( BoardRunner,
    PublicBoardRunner,
    deleteAttachmentHandler,
    deleteBoardHandler,
    getBoardHandler,
    getBoardsHandler,
    postBoardHandler,
    updateBoardHandler,
    uploadAttachmentHandler,
  )
import App.Server.API ()
import Data.Aeson (Value, decode, encode, object, (.=))
import Data.ByteString (ByteString)
import Data.IORef
import Data.List (find)
import Data.Text (Text)
import Data.Time.Calendar (fromGregorian)
import Data.Time.Clock (UTCTime (..), secondsToDiffTime)
import Effectful (Eff, IOE, runEff)
import qualified Effectful as Eff
import Effectful.Dispatch.Dynamic (interpret)
import Network.HTTP.Types (methodDelete, methodPost, methodPut)
import Network.Wai (Request)
import Servant
import Servant.Server.Experimental.Auth (AuthHandler, mkAuthHandler)
import Test.Hspec
import Test.Hspec.Wai

-- ─────────────────────────────────────────────
-- ヘルパー: JSON ボディを Value と照合する
--
-- MatchBody の型:
--   ([Header] -> LBS.ByteString -> Maybe String)
--     Nothing  → 一致
--     Just msg → 不一致（msg をエラーとして表示）
-- ─────────────────────────────────────────────

jsonBodyIs :: Value -> MatchBody
jsonBodyIs expected = MatchBody $ \_headers actual ->
  case decode actual of
    Nothing -> Just "レスポンスが JSON ではありません"
    Just got ->
      if (got :: Value) == expected
        then Nothing
        else Just $ "期待値:\n  " <> show expected <> "\n実際値:\n  " <> show got

-- ─────────────────────────────────────────────
-- stub: 認証は常に userId=1 で成功させる
-- ─────────────────────────────────────────────

stubAuthHandler :: AuthHandler Request AuthPrincipal
stubAuthHandler = mkAuthHandler $ \_req ->
  return $ AuthPrincipal (UserId 1) (Token "test-token")

-- ─────────────────────────────────────────────
-- テスト用の固定時刻
-- ─────────────────────────────────────────────

fixedTime :: UTCTime
fixedTime = UTCTime (fromGregorian 2026 4 1) (secondsToDiffTime 0)

-- ─────────────────────────────────────────────
-- fake: IORef でボード一覧を管理するインタープリタ
--
-- 型:
--   IOE :> es              ← liftIO を使うために必要
--   IORef [Board]          ← ボードのインメモリストレージ
--   IORef [BoardAttachment] ← 添付ファイルのインメモリストレージ
--   Eff (BoardRepo : es) a → Eff es a
--
-- フィールド名の多義性を避けるため、コマンドとエンティティは
-- すべて位置パターンで分解する。
-- ─────────────────────────────────────────────

runFakeBoardRepo ::
  (IOE Eff.:> es) =>
  IORef [Board] ->
  IORef [BoardAttachment] ->
  Eff (BoardRepo ': es) a ->
  Eff es a
runFakeBoardRepo boardRef attRef = interpret $ \_ -> \case
  CreateBoardOp (CreateBoardCommand title body cat) -> do
    boards <- liftIO $ readIORef boardRef
    let newId = BoardId (length boards + 1)
        newBoard =
          Board
            { boardId = newId,
              boardTitle = BoardTitle title,
              boardBodyMarkdown = BoardBodyMarkdown body,
              boardAuthorId = BoardAuthorId 1,
              boardCategory = BoardCategory cat,
              boardCreatedAt = BoardCreatedAt fixedTime,
              boardUpdatedAt = BoardUpdatedAt fixedTime
            }
    liftIO $ modifyIORef boardRef (++ [newBoard])
    return (Just newBoard)
  DeleteBoardOp (DeleteBoardCommand hid) -> do
    boards <- liftIO $ readIORef boardRef
    case find (\(Board bid _ _ _ _ _ _) -> bid == BoardId hid) boards of
      Nothing -> return False
      Just _ -> do
        liftIO $ modifyIORef boardRef (filter (\(Board bid _ _ _ _ _ _) -> bid /= BoardId hid))
        return True
  UpdateBoardOp (UpdateBoardCommand bid title body cat) -> do
    boards <- liftIO $ readIORef boardRef
    let targetId = BoardId bid
    case find (\(Board bid' _ _ _ _ _ _) -> bid' == targetId) boards of
      Nothing -> return Nothing
      Just old -> do
        let updated =
              old
                { boardTitle = BoardTitle title,
                  boardBodyMarkdown = BoardBodyMarkdown body,
                  boardCategory = BoardCategory cat,
                  boardUpdatedAt = BoardUpdatedAt fixedTime
                }
            newBoards = map (\b@(Board bid' _ _ _ _ _ _) -> if bid' == targetId then updated else b) boards
        liftIO $ writeIORef boardRef newBoards
        return (Just updated)
  SaveAttachmentOp (SaveAttachmentCommand bid aid url) -> do
    let att =
          BoardAttachment
            { boardId = BoardId bid,
              attachmentId = AttachmentId aid,
              attachmentUrl = AttachmentUrl url
            }
    liftIO $ modifyIORef attRef (++ [att])
    return (Just att)
  DeleteAttachmentOp (DeleteAttachmentCommand bid aid) -> do
    atts <- liftIO $ readIORef attRef
    case filter (\(BoardAttachment abid aaid _) -> abid == BoardId bid && aaid == AttachmentId aid) atts of
      [] -> return False
      _ -> do
        liftIO $ modifyIORef attRef (filter (\(BoardAttachment abid aaid _) -> not (abid == BoardId bid && aaid == AttachmentId aid)))
        return True

-- ─────────────────────────────────────────────
-- fake: 公開クエリのインタープリタ
--
-- 型:
--   Eff (PublicBoardQuery : es) a → Eff es a
-- ─────────────────────────────────────────────

runFakePublicBoardQuery ::
  (IOE Eff.:> es) =>
  IORef [Board] ->
  IORef [BoardAttachment] ->
  Eff (PublicBoardQuery ': es) a ->
  Eff es a
runFakePublicBoardQuery boardRef attRef = interpret $ \_ -> \case
  GetAllPublicBoardsQ -> do
    boards <- liftIO $ readIORef boardRef
    return (Just boards)
  GetPublicBoardQ bid -> do
    boards <- liftIO $ readIORef boardRef
    return $ find (\(Board bid' _ _ _ _ _ _) -> bid' == bid) boards
  GetAttachmentsForBoardOp bid -> do
    atts <- liftIO $ readIORef attRef
    return $ Just (filter (\(BoardAttachment bid' _ _) -> bid' == bid) atts)

-- ─────────────────────────────────────────────
-- テスト用 runner を組み立てる
-- ─────────────────────────────────────────────

fakeBoardRunner :: IORef [Board] -> IORef [BoardAttachment] -> AuthPrincipal -> BoardRunner
fakeBoardRunner boardRef attRef _user eff =
  runEff $ runFakePublicBoardQuery boardRef attRef $ runFakeBoardRepo boardRef attRef eff

fakePublicBoardRunner :: IORef [Board] -> IORef [BoardAttachment] -> PublicBoardRunner
fakePublicBoardRunner boardRef attRef eff =
  runEff $ runFakePublicBoardQuery boardRef attRef eff

-- ─────────────────────────────────────────────
-- テスト用 Application を組み立てる
-- ─────────────────────────────────────────────

testApp :: IORef [Board] -> IORef [BoardAttachment] -> Application
testApp boardRef attRef =
  let mkRun :: AuthPrincipal -> BoardRunner
      mkRun = fakeBoardRunner boardRef attRef
      runPublic :: PublicBoardRunner
      runPublic = fakePublicBoardRunner boardRef attRef
      handlers =
        postBoardHandler mkRun
          :<|> getBoardsHandler runPublic
          :<|> deleteBoardHandler mkRun
          :<|> getBoardHandler runPublic
          :<|> updateBoardHandler mkRun
          :<|> uploadAttachmentHandler mkRun
          :<|> deleteAttachmentHandler mkRun
          :<|> serveDirectoryWebApp "static/board/uploads"
   in serveWithContext
        (Proxy :: Proxy BoardAPI)
        (stubAuthHandler :. EmptyContext)
        handlers

-- ─────────────────────────────────────────────
-- テストデータ
-- ─────────────────────────────────────────────

sampleBoard :: Board
sampleBoard =
  Board
    { boardId = BoardId 1,
      boardTitle = BoardTitle "テスト投稿",
      boardBodyMarkdown = BoardBodyMarkdown "# Hello",
      boardAuthorId = BoardAuthorId 1,
      boardCategory = BoardCategory "general",
      boardCreatedAt = BoardCreatedAt fixedTime,
      boardUpdatedAt = BoardUpdatedAt fixedTime
    }

-- 添付ファイルのテスト用 UUID（固定値）
-- ByteString: テストのリクエストパス結合に使う
-- Text リテラルとして sampleAttachment 内で直接使用する
sampleAttachmentUUID :: ByteString
sampleAttachmentUUID = "550e8400-e29b-41d4-a716-446655440000"

sampleAttachment :: BoardAttachment
sampleAttachment =
  BoardAttachment
    { boardId = BoardId 1,
      attachmentId = AttachmentId "550e8400-e29b-41d4-a716-446655440000",
      attachmentUrl = AttachmentUrl "/api/board/uploads/550e8400-e29b-41d4-a716-446655440000.jpg"
    }

withFreshApp :: SpecWith ((), Application) -> Spec
withFreshApp = around $ \test -> do
  boardRef <- newIORef [sampleBoard]
  attRef <- newIORef [sampleAttachment]
  test ((), testApp boardRef attRef)

-- ─────────────────────────────────────────────
-- テスト本体
-- ─────────────────────────────────────────────

spec :: Spec
spec = withFreshApp $ do
  describe "GET /api/board/:id" $ do
    it "存在する id で 200 を返す" $
      get "/api/board/1" `shouldRespondWith` 200

    it "存在しない id で 404 を返す" $
      get "/api/board/999" `shouldRespondWith` 404

  describe "GET /api/board" $ do
    it "200 とボード一覧を返す" $
      get "/api/board" `shouldRespondWith` 200

  describe "POST /api/board" $ do
    it "正常なリクエストで 200 と CreatedBoardResponse を返す" $ do
      -- sampleBoard (id=1) が既存のため、新しいボードは id=2 になる
      let reqBody =
            encode $
              object
                [ "boardTitle" .= ("新しい投稿" :: Text),
                  "boardBodyMarkdown" .= ("# Hello" :: Text),
                  "boardCategory" .= ("general" :: Text)
                ]
          expectedRes =
            object
              [ "boardId" .= (2 :: Int),
                "createdBoardMessage" .= ("Board created successfully." :: Text),
                "boardCategory" .= ("general" :: Text)
              ]
      request methodPost "/api/board" [("Content-Type", "application/json")] reqBody
        `shouldRespondWith` ResponseMatcher
          { matchStatus = 200,
            matchHeaders = [],
            matchBody = jsonBodyIs expectedRes
          }

    it "タイトルが空のとき 400 を返す" $ do
      let body =
            encode $
              object
                [ "boardTitle" .= ("" :: Text),
                  "boardBodyMarkdown" .= ("# Hello" :: Text),
                  "boardCategory" .= ("general" :: Text)
                ]
      request methodPost "/api/board" [("Content-Type", "application/json")] body
        `shouldRespondWith` 400

    it "本文が空のとき 400 を返す" $ do
      let body =
            encode $
              object
                [ "boardTitle" .= ("タイトル" :: Text),
                  "boardBodyMarkdown" .= ("" :: Text),
                  "boardCategory" .= ("general" :: Text)
                ]
      request methodPost "/api/board" [("Content-Type", "application/json")] body
        `shouldRespondWith` 400

  describe "PUT /api/board/:id" $ do
    it "存在する id で 200 を返す" $ do
      let body =
            encode $
              object
                [ "putBoardTitle" .= ("更新後タイトル" :: Text),
                  "putBoardBodyMarkdown" .= ("# Updated" :: Text),
                  "putBoardCategory" .= ("tech" :: Text)
                ]
      request methodPut "/api/board/1" [("Content-Type", "application/json")] body
        `shouldRespondWith` 200

    it "存在しない id で 404 を返す" $ do
      let body =
            encode $
              object
                [ "putBoardTitle" .= ("x" :: Text),
                  "putBoardBodyMarkdown" .= ("x" :: Text),
                  "putBoardCategory" .= ("x" :: Text)
                ]
      request methodPut "/api/board/999" [("Content-Type", "application/json")] body
        `shouldRespondWith` 404

  describe "DELETE /api/board/:id" $ do
    it "存在する id で 200 を返す" $
      request methodDelete "/api/board/1" [] "" `shouldRespondWith` 200

    it "存在しない id で 404 を返す" $
      request methodDelete "/api/board/999" [] "" `shouldRespondWith` 404

  describe "DELETE /api/board/:boardId/:attachmentId" $ do
    it "存在する添付ファイルで 200 を返す" $
      request methodDelete ("/api/board/1/attachment/" <> sampleAttachmentUUID) [] ""
        `shouldRespondWith` 200

    it "存在しない attachmentId で 404 を返す" $
      request methodDelete "/api/board/1/attachment/00000000-0000-0000-0000-000000000000" [] ""
        `shouldRespondWith` 404

    it "board_id が違う場合 404 を返す" $
      request methodDelete ("/api/board/999/attachment/" <> sampleAttachmentUUID) [] ""
        `shouldRespondWith` 404
