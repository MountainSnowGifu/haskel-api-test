{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.User.UserSQLServer
  ( runUserRepoSqlServer,
  )
where

import App.Domain.Auth.Entity (Password (..), User (..), UserId (..), Username (..))
import App.Application.Auth.Repository (UserRepo (..))
import App.Infrastructure.DB.SqlServer (withMSSQLConn)
import App.Infrastructure.DB.Types (MSSQLPool)
import qualified Data.Text as T
import Database.MSSQLServer.Query (sql)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | UserRepo エフェクトを SQL Server で解釈するインタープリタ
--
--   FindByUserId のみ対応。トークン認証時に Redis から取得した UserId で
--   testdb.dbo.USERS を検索し User を返す。
runUserRepoSqlServer ::
  (IOE :> es) =>
  MSSQLPool ->
  Eff (UserRepo : es) a ->
  Eff es a
runUserRepoSqlServer pool = interpret $ \_ -> \case
  FindByUserId (UserId uid) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        sql conn ("SELECT id, username, password FROM testdb.dbo.USERS WHERE id = " <> T.pack (show uid)) ::
          IO [(Int, T.Text, T.Text)]
      case rows of
        [] -> return Nothing
        (i, u, p) : _ ->
          return $ Just $ User (Username u) (Password p) (UserId i)
  FindByUsername (Username uname) ->
    liftIO $ withMSSQLConn pool $ \conn -> do
      rows <-
        sql conn ("SELECT id, username, password FROM testdb.dbo.USERS WHERE username = '" <> uname <> "'") ::
          IO [(Int, T.Text, T.Text)]
      case rows of
        [] -> return Nothing
        (i, u, p) : _ ->
          return $ Just $ User (Username u) (Password p) (UserId i)
