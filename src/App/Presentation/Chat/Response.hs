{-# LANGUAGE OverloadedStrings #-}

module App.Presentation.Chat.Response
  ( ConnectionAckResponse,
    toConnectionAckResponse,
    BroadcastResponse,
    toBroadcastResponse,
  )
where

import App.Domain.Chat.Entity (ChatMessage (..), ConnectedClient (..))
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Text (Text)

-- | connection.ack イベント全体
data ConnectionAckResponse = ConnectionAckResponse
  { connAckUserId :: Text,
    connAckUserName :: Text,
    connAckRoomId :: Text,
    connAckConnectionId :: Text
  }

instance ToJSON ConnectionAckResponse where
  toJSON r =
    object
      [ "event" .= ("connection.ack" :: Text),
        "data"
          .= object
            [ "userId" .= connAckUserId r,
              "userName" .= connAckUserName r,
              "roomId" .= connAckRoomId r,
              "connectionId" .= connAckConnectionId r
            ]
      ]

toConnectionAckResponse :: ConnectedClient -> ConnectionAckResponse
toConnectionAckResponse c =
  ConnectionAckResponse
    { connAckUserId = clientUserId c,
      connAckUserName = clientUserName c,
      connAckRoomId = clientRoomId c,
      connAckConnectionId = clientConnId c
    }

-- | message.broadcast イベント全体
data BroadcastResponse = BroadcastResponse
  { bcastMessageId :: Text,
    bcastRoomId :: Text,
    bcastSenderUserId :: Text,
    bcastSenderUserName :: Text,
    bcastText :: Text,
    bcastSentAt :: Text
  }

instance ToJSON BroadcastResponse where
  toJSON r =
    object
      [ "event" .= ("message.broadcast" :: Text),
        "data"
          .= object
            [ "messageId" .= bcastMessageId r,
              "roomId" .= bcastRoomId r,
              "sender"
                .= object
                  [ "userId" .= bcastSenderUserId r,
                    "userName" .= bcastSenderUserName r
                  ],
              "text" .= bcastText r,
              "sentAt" .= bcastSentAt r
            ]
      ]

toBroadcastResponse :: ChatMessage -> BroadcastResponse
toBroadcastResponse msg =
  BroadcastResponse
    { bcastMessageId = chatMsgId msg,
      bcastRoomId = chatMsgRoomId msg,
      bcastSenderUserId = chatMsgUserId msg,
      bcastSenderUserName = chatMsgUserName msg,
      bcastText = chatMsgText msg,
      bcastSentAt = chatMsgSentAt msg
    }
