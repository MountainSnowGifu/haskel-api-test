module App.Marketing.Handler
  ( marketing,
  )
where

import App.Marketing.Types (ClientInfo (..), Email (..))
import Data.List (intercalate)
import Servant (Handler)

emailForClient :: ClientInfo -> Email
emailForClient c = Email from' to' subject' body'
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

marketing :: ClientInfo -> Handler Email
marketing clientinfo = return (emailForClient clientinfo)
