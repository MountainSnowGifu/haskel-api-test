{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module App.Domain.Message.Repository
  ( MessageRepo (..),
    findAll,
    save,
  )
where

import App.Domain.Message.Entity (Message)
import Effectful
import Effectful.Dispatch.Dynamic (send)

-- | MessageRepo エフェクト
--
--   型シグネチャで全操作を宣言する。
--   実装（SQLite/PostgreSQL 等）は Infrastructure 層で選択する。
--
--   GADTs の各コンストラクタが「操作」を表す:
--     FindAll :: MessageRepo m [Message]   -- 戻り値の型が [Message]
--     Save    :: Message -> MessageRepo m () -- 引数 Message、戻り値なし
data MessageRepo :: Effect where
  FindAll :: MessageRepo m [Message]
  Save :: Message -> MessageRepo m ()

type instance DispatchOf MessageRepo = Dynamic

-- | 全メッセージを取得する
--
--   型: MessageRepo :> es => Eff es [Message]
--   MessageRepo エフェクトがエフェクトスタック es に含まれていれば使える
findAll :: (MessageRepo :> es) => Eff es [Message]
findAll = send FindAll

-- | メッセージを保存する
save :: (MessageRepo :> es) => Message -> Eff es ()
save = send . Save
