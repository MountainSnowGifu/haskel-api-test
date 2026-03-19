module App.Application.Greeting.UseCase
  ( greetHello,
    getPosition,
  )
where

import App.Domain.Greeting.Entity (HelloMessage (..), Position (..))

-- | 挨拶メッセージを生成するユースケース
--
--   型: Maybe String -> HelloMessage
--
--   純粋関数。IO も Effect も不要。
greetHello :: Maybe String -> HelloMessage
greetHello mname = HelloMessage $ case mname of
  Nothing -> "Hello, anonymous coward"
  Just n -> "Hello, " ++ n

-- | 座標を生成するユースケース
--
--   型: Int -> Int -> Position
getPosition :: Int -> Int -> Position
getPosition = Position
