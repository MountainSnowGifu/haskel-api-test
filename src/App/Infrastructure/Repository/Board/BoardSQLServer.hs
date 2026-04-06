{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.Board.BoardSQLServer
  ( runBoardRepo,
    runPublicBoardQuery,
  )
where

import App.Application.Board.Command
  ( CreateBoardCommand (..),
    DeleteBoardCommand (..),
    SaveAttachmentCommand (..),
    UpdateBoardCommand (..),
  )
import App.Application.Board.PublicRepository (PublicBoardQuery (..))
import App.Application.Board.Repository (BoardRepo (..))
import App.Domain.Auth.Entity (UserId)
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
    userIdToAuthorId,
  )
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import Data.Text (Text)
import Data.Time (UTCTime)
import Database.MSSQLServer.Query
  ( RpcQuery (..),
    RpcResponse (..),
    StoredProcedure (..),
    intVal,
    nvarcharVal,
    rpc,
    withTransaction,
  )
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | RpcResponse からrows を取り出す。SQL Server がエラーを返した場合は IO 例外を投げる。
--
--   型:
--     RpcResponse a b -> IO b
rpcRows :: RpcResponse a b -> IO b
rpcRows (RpcResponse _ _ rs) = return rs
rpcRows (RpcResponseError info) = ioError (userError $ "SQL Server error: " ++ show info)

-- | BoardRepo エフェクトを MSSQL で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es              -- IO を実行できるエフェクトが必要
--     => MSSQLPool           -- コネクションプール
--     -> UserId              -- 認証済みユーザーID
--     -> Eff (BoardRepo : es) a   -- BoardRepo を含むスタAttachmentUrlック
--     -> Eff es a                -- BoardRepo を除いたスタック
runBoardRepo ::
  (IOE :> es) =>
  MSSQLPool ->
  UserId ->
  Eff (BoardRepo : es) a ->
  Eff es a
runBoardRepo pool authUserId = interpret $ \_ -> \case
  CreateBoardOp (CreateBoardCommand title bodyMarkdown category) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let BoardAuthorId uid = userIdToAuthorId authUserId
      withTransaction conn $ do
        rows <-
          rpcRows
            =<< ( rpc
                    conn
                    ( RpcQuery
                        SP_ExecuteSql
                        ( nvarcharVal "" (Just "INSERT INTO testdb.dbo.BOARDS (title, body_markdown, category, author_id, created_at, updated_at) OUTPUT INSERTED.id, INSERTED.title, INSERTED.body_markdown, INSERTED.category, INSERTED.author_id, INSERTED.created_at, INSERTED.updated_at VALUES (@Title, @BodyMarkdown, @Category, @AuthorId, GETDATE(), GETDATE())"),
                          nvarcharVal "" (Just "@Title nvarchar(max), @BodyMarkdown nvarchar(max), @Category nvarchar(max), @AuthorId int"),
                          nvarcharVal "@Title" (Just title),
                          nvarcharVal "@BodyMarkdown" (Just bodyMarkdown),
                          nvarcharVal "@Category" (Just category),
                          intVal "@AuthorId" (Just uid)
                        )
                    ) ::
                    IO (RpcResponse () [(Int, Text, Text, Text, Int, UTCTime, UTCTime)])
                )
        case rows of
          [] -> return Nothing
          (rowId, t, b, c, aid, ca, ua) : _ ->
            return $ Just $ Board (BoardId rowId) (BoardTitle t) (BoardBodyMarkdown b) (BoardAuthorId aid) (BoardCategory c) (BoardCreatedAt ca) (BoardUpdatedAt ua)
  DeleteBoardOp (DeleteBoardCommand {cmdDeleteBoardId = bId}) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let BoardAuthorId uid = userIdToAuthorId authUserId
      withTransaction conn $ do
        rows <-
          rpcRows
            =<< ( rpc
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
                )
        return (not (null rows))
  UpdateBoardOp (UpdateBoardCommand bId title bodyMarkdown category) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let BoardAuthorId uid = userIdToAuthorId authUserId
      withTransaction conn $ do
        rows <-
          rpcRows
            =<< ( rpc
                    conn
                    ( RpcQuery
                        SP_ExecuteSql
                        ( nvarcharVal "" (Just "UPDATE testdb.dbo.BOARDS SET title = @Title, body_markdown = @BodyMarkdown, category = @Category, updated_at = GETDATE() OUTPUT INSERTED.id, INSERTED.title, INSERTED.body_markdown, INSERTED.category, INSERTED.author_id, INSERTED.created_at, INSERTED.updated_at WHERE id = @BoardId AND author_id = @AuthorId"),
                          nvarcharVal "" (Just "@Title nvarchar(max), @BodyMarkdown nvarchar(max), @Category nvarchar(max), @BoardId int, @AuthorId int"),
                          nvarcharVal "@Title" (Just title),
                          nvarcharVal "@BodyMarkdown" (Just bodyMarkdown),
                          nvarcharVal "@Category" (Just category),
                          intVal "@BoardId" (Just bId),
                          intVal "@AuthorId" (Just uid)
                        )
                    ) ::
                    IO (RpcResponse () [(Int, Text, Text, Text, Int, UTCTime, UTCTime)])
                )
        case rows of
          [] -> return Nothing
          (rowId, t, b, c, aid, ca, ua) : _ ->
            return $ Just $ Board (BoardId rowId) (BoardTitle t) (BoardBodyMarkdown b) (BoardAuthorId aid) (BoardCategory c) (BoardCreatedAt ca) (BoardUpdatedAt ua)
  SaveAttachmentOp (SaveAttachmentCommand bid aid url) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      let BoardAuthorId uid = userIdToAuthorId authUserId
      withTransaction conn $ do
        rows <-
          rpcRows
            =<< ( rpc
                    conn
                    ( RpcQuery
                        SP_ExecuteSql
                        ( nvarcharVal "" (Just "INSERT INTO testdb.dbo.BOARD_ATTACHMENTS (board_id, attachment_id, attachment_url, author_id, created_at) OUTPUT CAST(INSERTED.attachment_id AS nvarchar(36)), INSERTED.attachment_url VALUES (@BoardId, @AttachmentId, @AttachmentUrl, @AuthorId, GETDATE())"),
                          nvarcharVal "" (Just "@BoardId int, @AttachmentId nvarchar(36), @AttachmentUrl nvarchar(max), @AuthorId int"),
                          intVal "@BoardId" (Just bid),
                          nvarcharVal "@AttachmentId" (Just aid),
                          nvarcharVal "@AttachmentUrl" (Just url),
                          intVal "@AuthorId" (Just uid)
                        )
                    ) ::
                    IO (RpcResponse () [(Text, Text)])
                )
        case rows of
          [] -> return Nothing
          _ -> return $ Just $ BoardAttachment (BoardId bid) (AttachmentId aid) (AttachmentUrl url)

runPublicBoardQuery ::
  (IOE :> es) =>
  MSSQLPool ->
  Eff (PublicBoardQuery : es) a ->
  Eff es a
runPublicBoardQuery pool = interpret $ \_ -> \case
  GetAllPublicBoardsQ ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        rpcRows
          =<< ( rpc
                  conn
                  ( RpcQuery
                      SP_ExecuteSql
                      (nvarcharVal "" (Just "SELECT id, title, body_markdown, category, author_id, created_at, updated_at FROM testdb.dbo.BOARDS"))
                  ) ::
                  IO (RpcResponse () [(Int, Text, Text, Text, Int, UTCTime, UTCTime)])
              )
      return $ Just $ map (\(rowId, t, b, c, aid, ca, ua) -> Board (BoardId rowId) (BoardTitle t) (BoardBodyMarkdown b) (BoardAuthorId aid) (BoardCategory c) (BoardCreatedAt ca) (BoardUpdatedAt ua)) rows
  GetPublicBoardQ (BoardId bId) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        rpcRows
          =<< ( rpc
                  conn
                  ( RpcQuery
                      SP_ExecuteSql
                      ( nvarcharVal "" (Just "SELECT id, title, body_markdown, category, author_id, created_at, updated_at FROM testdb.dbo.BOARDS WHERE id = @BoardId"),
                        nvarcharVal "" (Just "@BoardId int"),
                        intVal "@BoardId" (Just bId)
                      )
                  ) ::
                  IO (RpcResponse () [(Int, Text, Text, Text, Int, UTCTime, UTCTime)])
              )
      case rows of
        [] -> return Nothing
        (rowId, t, b, c, aid, ca, ua) : _ -> return $ Just $ Board (BoardId rowId) (BoardTitle t) (BoardBodyMarkdown b) (BoardAuthorId aid) (BoardCategory c) (BoardCreatedAt ca) (BoardUpdatedAt ua)
  GetAttachmentsForBoardOp (BoardId bid) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        rpcRows
          =<< ( rpc
                  conn
                  ( RpcQuery
                      SP_ExecuteSql
                      ( nvarcharVal "" (Just "SELECT board_id, CAST(attachment_id AS nvarchar(36)), attachment_url FROM testdb.dbo.BOARD_ATTACHMENTS WHERE board_id = @BoardId"),
                        nvarcharVal "" (Just "@BoardId int"),
                        intVal "@BoardId" (Just bid)
                      )
                  ) ::
                  IO (RpcResponse () [(Int, Text, Text)])
              )
      return $ Just $ map (\(bId, aId, aUrl) -> BoardAttachment (BoardId bId) (AttachmentId aId) (AttachmentUrl aUrl)) rows
