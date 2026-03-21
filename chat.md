# リアルタイムチャット WebSocket API 仕様書（ミニマム版）

## 1. 概要

本仕様書は、リアルタイムチャット機能のための WebSocket API の最小構成を定義する。  
対象機能は以下とする。

- 接続
- メッセージ送信
- ブロードキャスト
- 切断
- 生存確認

再接続、既読、タイピング通知、メッセージ編集・削除などは本仕様の対象外とする。

---

## 2. エンドポイント

### 本番環境

```text
wss://api.example.com/v1/chat/ws
```

### ローカル開発環境

```text
ws://localhost:8080/v1/chat/ws
```

---

## 3. 接続パラメータ

WebSocket 接続時に、クエリパラメータで認証情報と接続先ルームを指定する。

| パラメータ | 型     | 必須 | 説明               |
| ---------- | ------ | ---: | ------------------ |
| `token`    | string | 必須 | 認証トークン       |
| `roomId`   | string | 必須 | 接続対象のルームID |

### 接続例

```text
wss://api.example.com/v1/chat/ws?token=JWT_TOKEN&roomId=room-123
```

---

## 4. 通信形式

送受信するすべてのメッセージは JSON 形式とする。

### 共通フォーマット

```json
{
  "event": "string",
  "data": {}
}
```

### フィールド定義

| フィールド | 型     | 必須 | 説明                 |
| ---------- | ------ | ---: | -------------------- |
| `event`    | string | 必須 | イベント名           |
| `data`     | object | 必須 | イベントごとのデータ |

---

## 5. イベント一覧

### クライアント → サーバー

- `connection.init`
- `message.send`
- `ping`

### サーバー → クライアント

- `connection.ack`
- `message.broadcast`
- `pong`
- `error`

---

## 6. 接続仕様

WebSocket 接続成立後、クライアントは最初に `connection.init` イベントを送信しなければならない。

### 6.1 `connection.init`

#### 用途

接続初期化を行う。

#### 送信方向

クライアント → サーバー

#### リクエスト例

```json
{
  "event": "connection.init",
  "data": {
    "userId": "user-001",
    "userName": "taro",
    "roomId": "room-123"
  }
}
```

#### フィールド

| フィールド      | 型     | 必須 | 説明         |
| --------------- | ------ | ---: | ------------ |
| `data.userId`   | string | 必須 | ユーザーID   |
| `data.userName` | string | 必須 | 表示名       |
| `data.roomId`   | string | 必須 | 参加ルームID |

---

### 6.2 `connection.ack`

#### 用途

接続初期化成功を通知する。

#### 送信方向

サーバー → クライアント

#### レスポンス例

```json
{
  "event": "connection.ack",
  "data": {
    "userId": "user-001",
    "userName": "taro",
    "roomId": "room-123",
    "connectionId": "conn-001"
  }
}
```

#### フィールド

| フィールド          | 型     | 必須 | 説明         |
| ------------------- | ------ | ---: | ------------ |
| `data.userId`       | string | 必須 | ユーザーID   |
| `data.userName`     | string | 必須 | 表示名       |
| `data.roomId`       | string | 必須 | 参加ルームID |
| `data.connectionId` | string | 必須 | 接続ID       |

---

## 7. メッセージ送信仕様

### 7.1 `message.send`

#### 用途

チャットメッセージを送信する。

#### 送信方向

クライアント → サーバー

#### リクエスト例

```json
{
  "event": "message.send",
  "data": {
    "text": "こんにちは"
  }
}
```

#### フィールド

| フィールド  | 型     | 必須 | 説明               |
| ----------- | ------ | ---: | ------------------ |
| `data.text` | string | 必須 | 送信メッセージ本文 |

#### バリデーションルール

- `text` は必須
- `text` は文字列であること
- 空文字列は禁止
- 最大長は 1000 文字以内とする

---

## 8. ブロードキャスト仕様

### 8.1 `message.broadcast`

#### 用途

送信されたメッセージを同一ルーム参加者へ配信する。

#### 送信方向

サーバー → クライアント

#### レスポンス例

```json
{
  "event": "message.broadcast",
  "data": {
    "messageId": "msg-001",
    "roomId": "room-123",
    "sender": {
      "userId": "user-001",
      "userName": "taro"
    },
    "text": "こんにちは",
    "sentAt": "2026-03-21T10:00:00Z"
  }
}
```

#### フィールド

| フィールド             | 型     | 必須 | 説明                           |
| ---------------------- | ------ | ---: | ------------------------------ |
| `data.messageId`       | string | 必須 | サーバーが払い出すメッセージID |
| `data.roomId`          | string | 必須 | 配信対象ルームID               |
| `data.sender.userId`   | string | 必須 | 送信者ユーザーID               |
| `data.sender.userName` | string | 必須 | 送信者表示名                   |
| `data.text`            | string | 必須 | メッセージ本文                 |
| `data.sentAt`          | string | 必須 | 送信時刻（ISO 8601）           |

#### 備考

- 送信者本人を含む、同一ルーム内の全接続へ配信する
- メッセージIDはサーバー側で生成する

---

## 9. 生存確認

### 9.1 `ping`

#### 用途

接続生存確認を行う。

#### 送信方向

クライアント → サーバー

#### リクエスト例

```json
{
  "event": "ping",
  "data": {}
}
```

---

### 9.2 `pong`

#### 用途

`ping` に対する応答を返す。

#### 送信方向

サーバー → クライアント

#### レスポンス例

```json
{
  "event": "pong",
  "data": {}
}
```

#### 推奨運用

- クライアントは 30 秒ごとに `ping` を送信する
- 一定時間 `pong` を受信できない場合は切断扱いとする

---

## 10. エラー仕様

### 10.1 `error`

#### 用途

リクエスト不正、認証失敗、内部エラーなどを通知する。

#### 送信方向

サーバー → クライアント

#### レスポンス例

```json
{
  "event": "error",
  "data": {
    "code": "MESSAGE_INVALID",
    "message": "text は必須です"
  }
}
```

#### フィールド

| フィールド     | 型     | 必須 | 説明             |
| -------------- | ------ | ---: | ---------------- |
| `data.code`    | string | 必須 | エラーコード     |
| `data.message` | string | 必須 | エラーメッセージ |

### 10.2 エラーコード一覧

| コード            | 説明                 |
| ----------------- | -------------------- |
| `AUTH_FAILED`     | 認証失敗             |
| `ROOM_NOT_FOUND`  | ルームが存在しない   |
| `MESSAGE_INVALID` | メッセージ内容が不正 |
| `INTERNAL_ERROR`  | サーバー内部エラー   |

---

## 11. 切断仕様

### 11.1 正常切断

クライアントは WebSocket Close を用いて接続を終了する。

### 11.2 サーバー動作

切断検知時、サーバーは以下を実施する。

- 接続情報を破棄する
- ルーム管理情報から対象接続を削除する

### 11.3 備考

本ミニマム版では、他の参加者への退出通知は行わない。

---

## 12. サーバー処理要件

### 12.1 接続時

- `token` を検証する
- `roomId` の存在を確認する
- 接続を対象ルームへ紐付ける
- `connection.ack` を返却する

### 12.2 メッセージ受信時

- JSON をパースする
- `event` を判定する
- `message.send` の場合、`text` をバリデーションする
- メッセージIDを採番する
- ルーム参加者全員へ `message.broadcast` を送信する

### 12.3 切断時

- 接続管理情報を削除する

---

## 13. データ構造

### 13.1 接続情報

```json
{
  "connectionId": "conn-001",
  "userId": "user-001",
  "userName": "taro",
  "roomId": "room-123"
}
```

### 13.2 メッセージ情報

```json
{
  "messageId": "msg-001",
  "roomId": "room-123",
  "sender": {
    "userId": "user-001",
    "userName": "taro"
  },
  "text": "こんにちは",
  "sentAt": "2026-03-21T10:00:00Z"
}
```

---

## 14. シーケンス

### 14.1 接続

1. クライアントが WebSocket 接続を開始する
2. クライアントが `connection.init` を送信する
3. サーバーが `connection.ack` を返却する

### 14.2 メッセージ送信

1. クライアントが `message.send` を送信する
2. サーバーが内容を検証する
3. サーバーが `message.broadcast` をルーム全体へ送信する

### 14.3 切断

1. クライアントが WebSocket Close を実行する
2. サーバーが接続情報を削除する

---

## 15. 通信例

### 15.1 接続初期化

#### クライアント → サーバー

```json
{
  "event": "connection.init",
  "data": {
    "userId": "user-001",
    "userName": "taro",
    "roomId": "room-123"
  }
}
```

#### サーバー → クライアント

```json
{
  "event": "connection.ack",
  "data": {
    "userId": "user-001",
    "userName": "taro",
    "roomId": "room-123",
    "connectionId": "conn-001"
  }
}
```

### 15.2 メッセージ送信

#### クライアント → サーバー

```json
{
  "event": "message.send",
  "data": {
    "text": "こんにちは"
  }
}
```

#### サーバー → クライアント

```json
{
  "event": "message.broadcast",
  "data": {
    "messageId": "msg-001",
    "roomId": "room-123",
    "sender": {
      "userId": "user-001",
      "userName": "taro"
    },
    "text": "こんにちは",
    "sentAt": "2026-03-21T10:00:00Z"
  }
}
```

### 15.3 生存確認

#### クライアント → サーバー

```json
{
  "event": "ping",
  "data": {}
}
```

#### サーバー → クライアント

```json
{
  "event": "pong",
  "data": {}
}
```

### 15.4 エラー

```json
{
  "event": "error",
  "data": {
    "code": "AUTH_FAILED",
    "message": "認証に失敗しました"
  }
}
```

---

## 16. 制約事項

- 1 接続は 1 ルームにのみ所属する
- 本仕様では再接続をサポートしない
- 本仕様ではメッセージ永続化方式を規定しない
- 本仕様では既読、未読、通知制御を扱わない

---

## 17. 今後の拡張候補

- 再接続
- メッセージ送信ACK
- タイピング通知
- 既読通知
- メッセージ編集
- メッセージ削除
- 添付ファイル送信
- レート制限
- 権限管理

---

## 18. 付録: 最小イベント定義

```json
{
  "name": "minimal-realtime-chat-websocket-api",
  "version": "1.0.0",
  "endpoint": "/v1/chat/ws",
  "clientEvents": ["connection.init", "message.send", "ping"],
  "serverEvents": ["connection.ack", "message.broadcast", "pong", "error"]
}
```
