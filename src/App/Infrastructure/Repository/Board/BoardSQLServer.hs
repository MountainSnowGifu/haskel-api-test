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
import qualified Data.Text as T
import Database.MSSQLServer.Query (Only (..), sql, withTransaction)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

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
          esc = T.replace "'" "''"
          insertSql =
            "INSERT INTO testdb.dbo.BOARDS (title, body_markdown, author_id, created_at, updated_at) "
              <> "OUTPUT INSERTED.id, INSERTED.title, INSERTED.body_markdown "
              <> "VALUES (N'"
              <> esc title
              <> "', N'"
              <> esc bodyMarkdown
              <> "', "
              <> T.pack (show uid)
              <> ", GETDATE(), GETDATE())"
      withTransaction conn $ do
        rows <-
          sql conn insertSql ::
            IO [(Int, T.Text, T.Text)]
        case rows of
          [] -> return Nothing
          ((rowId, t, b) : _) ->
            return $ Just $ Board rowId t b