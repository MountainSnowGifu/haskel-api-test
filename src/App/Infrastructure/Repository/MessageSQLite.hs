{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.MessageSQLite
  ( runMessageRepoSQLite,
  )
where

import App.Domain.Message.Entity (Message (..))
import App.Domain.Message.Repository (MessageRepo (..))
import App.Infrastructure.DB.Types (SqliteDb (..))
import Database.SQLite.Simple (execute, query_, withConnection)
import Database.SQLite.Simple.Types (Only (..))
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | MessageRepo エフェクトを SQLite で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es           -- IO を実行できるエフェクトが必要
--     => FilePath         -- SQLite ファイルパス
--     -> Eff (MessageRepo : es) a   -- MessageRepo を含むスタック
--     -> Eff es a                   -- MessageRepo を除いたスタック
--
--   interpret の引数 (env, op) の op が各コンストラクタにマッチする
runMessageRepoSQLite ::
  (IOE :> es) =>
  SqliteDb ->
  Eff (MessageRepo : es) a ->
  Eff es a
runMessageRepoSQLite (SqliteDb dbfile) = interpret $ \_ -> \case
  FindAll ->
    liftIO $
      withConnection dbfile $ \conn ->
        map (\(Only msg) -> Message msg) <$> query_ conn "SELECT msg FROM messages"
  Save (Message msg) ->
    liftIO $
      withConnection dbfile $ \conn ->
        execute conn "INSERT INTO messages VALUES (?)" (Only msg)
