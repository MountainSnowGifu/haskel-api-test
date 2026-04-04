{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.Board.BoardSQLServer
  ( runBoardRepo,
  )
where

import App.Application.Board.Command (CreateBoardCommand (..))
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
