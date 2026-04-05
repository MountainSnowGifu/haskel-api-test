{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module App.Presentation.Board.API
  ( BoardAPI,
  )
where

import App.Presentation.Board.Request (PostBoardRequest, PutBoardRequest)
import App.Presentation.Board.Response (AttachmentResponse, BoardResponse, CreatedBoardResponse)
import Servant
import Servant.Multipart (MultipartData, MultipartForm, Tmp)

type BoardAPI =
  AuthProtect "token-auth" :> "api" :> "board" :> ReqBody '[JSON] PostBoardRequest :> Post '[JSON] CreatedBoardResponse
    :<|> "api" :> "board" :> Get '[JSON] [BoardResponse]
    :<|> AuthProtect "token-auth" :> "api" :> "board" :> Capture "id" Int :> Delete '[JSON] NoContent
    :<|> "api" :> "board" :> Capture "id" Int :> Get '[JSON] BoardResponse
    :<|> AuthProtect "token-auth" :> "api" :> "board" :> Capture "id" Int :> ReqBody '[JSON] PutBoardRequest :> Put '[JSON] BoardResponse
    :<|> AuthProtect "token-auth" :> "api" :> "board" :> Capture "id" Int :> "attachment" :> MultipartForm Tmp (MultipartData Tmp) :> Post '[JSON] AttachmentResponse
    :<|> "api" :> "board" :> "uploads" :> Raw
