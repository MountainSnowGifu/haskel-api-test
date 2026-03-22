{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module App.Infrastructure.Repository.RecordSQLite
  ( runRecordRepo,
  )
where

import App.Domain.Auth.Entity (User (..), UserId (..))
import App.Domain.BudgetTracker.Entity (Record (..))
import App.Domain.BudgetTracker.Repository (RecordRepo (..))
import App.Infrastructure.DB.Types (SqliteDb (..))
import App.Application.BudgetTracker.Command (CreateRecordCommand (..))
import Data.Text (unpack)
import Database.SQLite.Simple (Only (..), execute, lastInsertRowId, query, withConnection)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

-- | RecordRepo エフェクトを SQLite で解釈するインタープリタ
--
--   型シグネチャ:
--     IOE :> es               -- IO を実行できるエフェクトが必要
--     => SqliteDb             -- DBファイルパス
--     -> User                 -- 認証済みユーザー
--     -> Eff (RecordRepo : es) a  -- RecordRepo を含むスタック
--     -> Eff es a                 -- RecordRepo を除いたスタック
runRecordRepo ::
  (IOE :> es) =>
  SqliteDb ->
  User ->
  Eff (RecordRepo : es) a ->
  Eff es a
runRecordRepo (SqliteDb dbfile) user = interpret $ \_ -> \case
  GetRecordsAll ->
    liftIO $ withConnection dbfile $ \conn -> do
      let uid = unUserId (userUserId user)
      -- print uid
      -- print (Only uid)
      rows <- query conn "SELECT id, user_id, type, category, amount, date, memo FROM records WHERE user_id = ?" (Only uid) :: IO [(Int, Int, String, String, Int, String, String)]
      print rows
      return $ map (\(i, u, t, c, a, d, m) -> Record {recordId = i, recordUserId = u, recordType = t, recordCategory = c, recordAmount = a, recordDate = d, recordMemo = m}) rows
  PostRecord cmd ->
    liftIO $ withConnection dbfile $ \conn -> do
      let uid = unUserId (userUserId user)
      execute conn
        "INSERT INTO records (user_id, type, category, amount, date, memo) VALUES (?,?,?,?,?,?)"
        (uid, unpack (cmdType cmd), unpack (cmdCategory cmd), cmdAmount cmd, unpack (cmdDate cmd), unpack (cmdMemo cmd))
      rowId <- fromIntegral <$> lastInsertRowId conn
      return Record
        { recordId       = rowId
        , recordUserId   = uid
        , recordType     = unpack (cmdType cmd)
        , recordCategory = unpack (cmdCategory cmd)
        , recordAmount   = cmdAmount cmd
        , recordDate     = unpack (cmdDate cmd)
        , recordMemo     = unpack (cmdMemo cmd)
        }
