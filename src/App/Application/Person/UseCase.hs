module App.Application.Person.UseCase
  ( getAge,
    getName,
    echoName,
  )
where

import App.Core.Config (Config (..))

-- | Config から年齢エンドポイントの応答文字列を生成するユースケース
--
--   型: Config -> String
--
--   純粋関数。Config を受け取り文字列を返す。
getAge :: Config -> String
getAge cfg = host cfg ++ ":" ++ show (port cfg) ++ ":31"

-- | 名前を整形するユースケース
--
--   型: String -> String
getName :: String -> String
getName nameIn = "name: " ++ nameIn

-- | 名前をそのまま返すユースケース
--
--   型: String -> String
--
--   Handler 側でログ出力などの副作用を加えられるよう、
--   純粋な本体ロジックをここに切り出す。
echoName :: String -> String
echoName = id
