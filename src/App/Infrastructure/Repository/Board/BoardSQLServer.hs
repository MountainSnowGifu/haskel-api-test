{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.Board.BoardSQLServer
  ( runBoardRepo,
    runPublicBoardRepo,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..), SaveAttachmentCommand (..), UpdateBoardCommand (..))
import App.Application.Board.Repository (BoardRepo (..))
import App.Domain.Auth.Entity (UserId (..))
import App.Domain.Board.Entity (Board (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Text (Text)
import Database.MSSQLServer.Query (RpcQuery (..), RpcResponse (..), StoredProcedure (..), intVal, nvarcharVal, rpc, withTransaction)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | BoardRepo エフェクトを MSSQL で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es              -- IO を実行できるエフェクトが必要
--     => MSSQLPool           -- コネクションプール
--     -> UserId              -- 認証済みユーザーID
--     -> Eff (BoardRepo : es) a   -- BoardRepo を含むスタック
--     -> Eff es a                -- BoardRepo を除いたスタック
runBoardRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  UserId ->
  Eff (BoardRepo : es) a ->
  Eff es a
runBoardRepo pool authUserId = interpret $ \_ -> \case
  CreateBoardOp (CreateBoardCommand title bodyMarkdown) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      withTransaction conn $ do
        RpcResponse _ _ rows <-
          rpc
            conn
            ( RpcQuery
                SP_ExecuteSql
                ( nvarcharVal "" (Just "INSERT INTO testdb.dbo.BOARDS (title, body_markdown, author_id, created_at, updated_at) OUTPUT INSERTED.id, INSERTED.title, INSERTED.body_markdown VALUES (@Title, @BodyMarkdown, @AuthorId, GETDATE(), GETDATE())"),
                  nvarcharVal "" (Just "@Title nvarchar(max), @BodyMarkdown nvarchar(max), @AuthorId int"),
                  nvarcharVal "@Title" (Just title),
                  nvarcharVal "@BodyMarkdown" (Just bodyMarkdown),
                  intVal "@AuthorId" (Just uid)
                )
            ) ::
            IO (RpcResponse () [(Int, Text, Text)])
        case rows of
          [] -> return Nothing
          (rowId, t, b) : _ ->
            return $ Just $ Board rowId t b
  GetAllBoardsOp ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "SELECT id, title, body_markdown FROM testdb.dbo.BOARDS WHERE author_id = @AuthorId"),
                nvarcharVal "" (Just "@AuthorId int"),
                intVal "@AuthorId" (Just uid)
              )
          ) ::
          IO (RpcResponse () [(Int, Text, Text)])
      return $ map (\(rowId, t, b) -> Board rowId t b) rows
  GetAllPublicBoardsOp ->
    error "runBoardRepo: GetAllPublicBoardsOp is not supported."
  GetBoardOp bId ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "SELECT id, title, body_markdown FROM testdb.dbo.BOARDS WHERE id = @BoardId AND author_id = @AuthorId"),
                nvarcharVal "" (Just "@BoardId int, @AuthorId int"),
                intVal "@BoardId" (Just bId),
                intVal "@AuthorId" (Just uid)
              )
          ) ::
          IO (RpcResponse () [(Int, Text, Text)])
      case rows of
        [] -> return Nothing
        (rowId, t, b) : _ -> return $ Just $ Board rowId t b
  GetPublicBoardOp _ ->
    error "runBoardRepo: GetPublicBoardOp is not supported."
  DeleteBoardOp bId ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      withTransaction conn $ do
        _ <-
          rpc
            conn
            ( RpcQuery
                SP_ExecuteSql
                ( nvarcharVal "" (Just "DELETE FROM testdb.dbo.BOARDS OUTPUT DELETED.id, DELETED.title WHERE id = @BoardId AND author_id = @AuthorId"),
                  nvarcharVal "" (Just "@BoardId int, @AuthorId int"),
                  intVal "@BoardId" (Just bId),
                  intVal "@AuthorId" (Just uid)
                )
            ) ::
            IO (RpcResponse () [(Int, Text)])
        return ()
  UpdateBoardOp (UpdateBoardCommand bId title bodyMarkdown) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      withTransaction conn $ do
        RpcResponse _ _ rows <-
          rpc
            conn
            ( RpcQuery
                SP_ExecuteSql
                ( nvarcharVal "" (Just "UPDATE testdb.dbo.BOARDS SET title = @Title, body_markdown = @BodyMarkdown, updated_at = GETDATE() OUTPUT INSERTED.id, INSERTED.title, INSERTED.body_markdown WHERE id = @BoardId AND author_id = @AuthorId"),
                  nvarcharVal "" (Just "@Title nvarchar(max), @BodyMarkdown nvarchar(max), @BoardId int, @AuthorId int"),
                  nvarcharVal "@Title" (Just title),
                  nvarcharVal "@BodyMarkdown" (Just bodyMarkdown),
                  intVal "@BoardId" (Just bId),
                  intVal "@AuthorId" (Just uid)
                )
            ) ::
            IO (RpcResponse () [(Int, Text, Text)])
        case rows of
          [] -> return Nothing
          (rowId, t, b) : _ -> return $ Just $ Board rowId t b
  SaveAttachmentOp (SaveAttachmentCommand aid url) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let uid = unUserId authUserId
      withTransaction conn $ do
        _ <-
          rpc
            conn
            ( RpcQuery
                SP_ExecuteSql
                ( nvarcharVal "" (Just "INSERT INTO testdb.dbo.BOARD_ATTACHMENTS (attachment_id, attachment_url, author_id, created_at) OUTPUT INSERTED.attachment_id, INSERTED.author_id VALUES (@AttachmentId, @AttachmentUrl, @AuthorId, GETDATE())"),
                  nvarcharVal "" (Just "@AttachmentId nvarchar(36), @AttachmentUrl nvarchar(max), @AuthorId int"),
                  nvarcharVal "@AttachmentId" (Just aid),
                  nvarcharVal "@AttachmentUrl" (Just url),
                  intVal "@AuthorId" (Just uid)
                )
            ) ::
            IO (RpcResponse () [(Text, Int)])
        return ()

runPublicBoardRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  Eff (BoardRepo : es) a ->
  Eff es a
runPublicBoardRepo pool = interpret $ \_ -> \case
  GetAllPublicBoardsOp ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              (nvarcharVal "" (Just "SELECT id, title, body_markdown FROM testdb.dbo.BOARDS"))
          ) ::
          IO (RpcResponse () [(Int, Text, Text)])
      return $ map (\(rowId, t, b) -> Board rowId t b) rows
  CreateBoardOp _ ->
    error "runPublicBoardRepo: CreateBoardOp is not supported."
  GetAllBoardsOp ->
    error "runPublicBoardRepo: GetAllBoardsOp is not supported."
  GetBoardOp _ ->
    error "runPublicBoardRepo: GetBoardOp is not supported."
  GetPublicBoardOp bId ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      RpcResponse _ _ rows <-
        rpc
          conn
          ( RpcQuery
              SP_ExecuteSql
              ( nvarcharVal "" (Just "SELECT id, title, body_markdown FROM testdb.dbo.BOARDS WHERE id = @BoardId"),
                nvarcharVal "" (Just "@BoardId int"),
                intVal "@BoardId" (Just bId)
              )
          ) ::
          IO (RpcResponse () [(Int, Text, Text)])
      case rows of
        [] -> return Nothing
        (rowId, t, b) : _ -> return $ Just $ Board rowId t b
  DeleteBoardOp _ ->
    error "runPublicBoardRepo: DeleteBoardOp is not supported."
  UpdateBoardOp _ ->
    error "runPublicBoardRepo: UpdateBoardOp is not supported."
  SaveAttachmentOp _ ->
    error "runPublicBoardRepo: SaveAttachmentOp is not supported."
