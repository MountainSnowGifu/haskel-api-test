module App.Application.Marketing.UseCase
  ( createEmail,
  )
where

import App.Domain.Marketing.Entity (ClientInfo (..), Email (..))
import Data.List (intercalate)

-- | 顧客情報からマーケティングメールを生成するユースケース
--
--   型: ClientInfo -> Email
--
--   純粋関数。IO も Effect も不要。
--   ビジネスロジック（メール本文の組み立て）がここに集約される。
createEmail :: ClientInfo -> Email
createEmail c = Email from' to' subject' body'
  where
    from' = "great@company.com"
    to' = clientEmail c
    subject' = "Hey " ++ clientName c ++ ", we miss you!"
    body' =
      "Hi "
        ++ clientName c
        ++ ",\n\n"
        ++ "Since you've recently turned "
        ++ show (clientAge c)
        ++ ", have you checked out our latest "
        ++ intercalate ", " (clientInterestedIn c)
        ++ " products? Give us a visit!"
