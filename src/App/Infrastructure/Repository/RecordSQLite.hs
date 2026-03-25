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
import App.Domain.BudgetTracker.Entity (NewRecord (..), Record (..), RecordType (..))
import App.Domain.BudgetTracker.Repository (RecordRepo (..))
import App.Infrastructure.DB.Types (SqliteDb (..))
import Data.Text (Text)
import Database.SQLite.Simple (Only (..), execute, lastInsertRowId, query, withConnection)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)

toRecordType :: Text -> RecordType
toRecordType "income" = Income
toRecordType _        = Expense

fromRecordType :: RecordType -> Text
fromRecordType Income  = "income"
fromRecordType Expense = "expense"

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
      rows <- query conn "SELECT id, user_id, type, category, amount, date, memo FROM records WHERE user_id = ?" (Only uid) :: IO [(Int, Int, Text, Text, Int, Text, Text)]
      print rows
      return $ map (\(i, u, t, c, a, d, m) -> Record {recordId = i, recordUserId = u, recordType = toRecordType t, recordCategory = c, recordAmount = a, recordDate = d, recordMemo = m}) rows
  PostRecord nr ->
    liftIO $ withConnection dbfile $ \conn -> do
      let uid = unUserId (userUserId user)
      execute
        conn
        "INSERT INTO records (user_id, type, category, amount, date, memo) VALUES (?,?,?,?,?,?)"
        (uid, fromRecordType (newRecordType nr), newRecordCategory nr, newRecordAmount nr, newRecordDate nr, newRecordMemo nr)
      rowId <- fromIntegral <$> lastInsertRowId conn
      return
        Record
          { recordId       = rowId,
            recordUserId   = uid,
            recordType     = newRecordType nr,
            recordCategory = newRecordCategory nr,
            recordAmount   = newRecordAmount nr,
            recordDate     = newRecordDate nr,
            recordMemo     = newRecordMemo nr
          }
  DeleteRecord rid ->
    liftIO $ withConnection dbfile $ \conn -> do
      execute conn "DELETE FROM records WHERE id = ?" (Only rid)
      return (Just ())
  GetRecordsByMonth month ->
    liftIO $ withConnection dbfile $ \conn -> do
      let uid = unUserId (userUserId user)
      rows <- query conn "SELECT id, user_id, type, category, amount, date, memo FROM records WHERE user_id = ? AND strftime('%Y-%m', date) = ?" (uid, month) :: IO [(Int, Int, Text, Text, Int, Text, Text)]
      return $ map (\(i, u, t, c, a, d, m) -> Record {recordId = i, recordUserId = u, recordType = toRecordType t, recordCategory = c, recordAmount = a, recordDate = d, recordMemo = m}) rows
