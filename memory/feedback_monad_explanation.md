---
name: モナド・Functor の説明スタイル
description: Functor/Monad の説明で「箱」「文脈」などの比喩を使わず型で説明する
type: feedback
---

`<$>` や `>>=` などの説明で「文脈は保つ」「箱の中を変換」などの比喩を使わない。

**Why:** CLAUDE.md に明記されており、ユーザーが実際に指摘した（`Maybe` の `<$>` 説明で「文脈は保つ」と書いたところ違反を指摘された）。

**How to apply:** `Functor`/`Monad` のインスタンス定義（`fmap f Nothing = Nothing` など）を直接示す。型と定義から動作を導く説明にする。
