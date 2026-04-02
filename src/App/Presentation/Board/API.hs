{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Board.API
  ( BoardAPI,
  )
where

import App.Presentation.Board.Request (PostBoardRequest)
import App.Presentation.Board.Response (CreatedBoardResponse)
import Servant

type BoardAPI =
  AuthProtect "token-auth" :> "api" :> "board" :> ReqBody '[JSON] PostBoardRequest :> Post '[JSON] CreatedBoardResponse