# WEB APP 初学者向けタスク管理アプリ バックエンドAPI仕様

> 「初学者向けのタスク管理Webアプリ」を前提に、わかりやすく・実装しやすいバックエンドAPI仕様を、最初に作るべき最小構成として整理します。
>
> 今回は **REST API** で設計します。  
> 理由は、初学者にとって理解しやすく、フロントエンドとも連携しやすいからです。

---

## 1. 前提

### 想定するアプリの機能

初学者向けなので、まずは次の機能に絞ります。

- ユーザー登録 / ログイン
- タスクの作成
- タスク一覧の取得
- タスクの詳細取得
- タスクの更新
- タスクの削除
- タスクの完了 / 未完了切り替え
- タスクの絞り込み

---

## 2. データモデル

まずはAPIの土台になるデータを決めます。

### User

```json
{
  "id": 1,
  "name": "Taro",
  "email": "taro@example.com",
  "passwordHash": "hashed_password",
  "createdAt": "2026-03-19T10:00:00Z",
  "updatedAt": "2026-03-19T10:00:00Z"
}
```

### Task

```json
{
  "id": 101,
  "userId": 1,
  "title": "買い物に行く",
  "description": "牛乳とパンを買う",
  "status": "todo",
  "priority": "medium",
  "dueDate": "2026-03-20",
  "createdAt": "2026-03-19T10:30:00Z",
  "updatedAt": "2026-03-19T10:30:00Z"
}
```

---

## 3. エンティティ設計のポイント

### Task の主な項目

| 項目                     | 説明                   |
| ------------------------ | ---------------------- |
| `id`                     | タスクID               |
| `userId`                 | どのユーザーのタスクか |
| `title`                  | タスク名               |
| `description`            | 詳細説明               |
| `status`                 | 状態                   |
| `priority`               | 優先度                 |
| `dueDate`                | 期限                   |
| `createdAt`, `updatedAt` | 作成/更新日時          |

### status の候補

初学者向けなら、まずはこれで十分です。

| 値      | 意味   |
| ------- | ------ |
| `todo`  | 未着手 |
| `doing` | 作業中 |
| `done`  | 完了   |

### priority の候補

| 値       |
| -------- |
| `low`    |
| `medium` |
| `high`   |

---

## 4. API設計方針

### ベースURL

```
/api/v1
```

例:

```
GET /api/v1/tasks
```

### 認証方式

シンプルに **JWT認証** を採用します。

**流れ:**

1. ログイン成功
2. サーバーがJWTを返す
3. クライアントは以後のAPIで `Authorization: Bearer <token>` を送る

---

## 5. API一覧

### 5-1. 認証API

#### 1) ユーザー登録

`POST /api/v1/auth/register`

**リクエスト**

```json
{
  "name": "Taro",
  "email": "taro@example.com",
  "password": "password123"
}
```

**レスポンス** — `201 Created`

```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "Taro",
    "email": "taro@example.com"
  }
}
```

**バリデーション**

- `name`: 必須、1〜50文字
- `email`: 必須、メール形式、一意
- `password`: 必須、8文字以上

#### 2) ログイン

`POST /api/v1/auth/login`

**リクエスト**

```json
{
  "email": "taro@example.com",
  "password": "password123"
}
```

**レスポンス** — `200 OK`

```json
{
  "message": "Login successful",
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "name": "Taro",
    "email": "taro@example.com"
  }
}
```

#### 3) ログアウト

`POST /api/v1/auth/logout`

JWTを使う場合、完全なサーバー側ログアウトは実装方式によります。  
初学者向けなら以下のどちらかです。

- フロント側でトークンを削除する
- ブラックリスト方式を後で導入する

**レスポンス** — `200 OK`

```json
{
  "message": "Logout successful"
}
```

### 5-2. ユーザー情報API

#### 4) ログイン中ユーザー取得

`GET /api/v1/users/me`

**ヘッダー**

```
Authorization: Bearer <token>
```

**レスポンス** — `200 OK`

```json
{
  "id": 1,
  "name": "Taro",
  "email": "taro@example.com",
  "createdAt": "2026-03-19T10:00:00Z"
}
```

### 5-3. タスクAPI

#### 5) タスク作成

`POST /api/v1/tasks`

**リクエスト**

```json
{
  "title": "買い物に行く",
  "description": "牛乳とパンを買う",
  "priority": "medium",
  "dueDate": "2026-03-20"
}
```

**レスポンス** — `201 Created`

```json
{
  "message": "Task created successfully",
  "task": {
    "id": 101,
    "userId": 1,
    "title": "買い物に行く",
    "description": "牛乳とパンを買う",
    "status": "todo",
    "priority": "medium",
    "dueDate": "2026-03-20",
    "createdAt": "2026-03-19T10:30:00Z",
    "updatedAt": "2026-03-19T10:30:00Z"
  }
}
```

**バリデーション**

- `title`: 必須、1〜100文字
- `description`: 任意、1000文字以内
- `priority`: 任意、`low` | `medium` | `high`
- `dueDate`: 任意、`YYYY-MM-DD`

#### 6) タスク一覧取得

`GET /api/v1/tasks`

**クエリパラメータ例**

```
/api/v1/tasks?status=todo&priority=high&page=1&limit=10
```

**使えるクエリ**

| パラメータ | 説明                               |
| ---------- | ---------------------------------- |
| `status`   | ステータスで絞り込み               |
| `priority` | 優先度で絞り込み                   |
| `keyword`  | タイトル検索                       |
| `page`     | ページ番号                         |
| `limit`    | 1ページあたりの件数                |
| `sortBy`   | `createdAt`, `dueDate`, `priority` |
| `order`    | `asc`, `desc`                      |

**レスポンス** — `200 OK`

```json
{
  "tasks": [
    {
      "id": 101,
      "title": "買い物に行く",
      "description": "牛乳とパンを買う",
      "status": "todo",
      "priority": "medium",
      "dueDate": "2026-03-20",
      "createdAt": "2026-03-19T10:30:00Z",
      "updatedAt": "2026-03-19T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "totalPages": 1
  }
}
```

#### 7) タスク詳細取得

`GET /api/v1/tasks/:id`

例: `GET /api/v1/tasks/101`

**レスポンス** — `200 OK`

```json
{
  "id": 101,
  "title": "買い物に行く",
  "description": "牛乳とパンを買う",
  "status": "todo",
  "priority": "medium",
  "dueDate": "2026-03-20",
  "createdAt": "2026-03-19T10:30:00Z",
  "updatedAt": "2026-03-19T10:30:00Z"
}
```

#### 8) タスク更新

`PUT /api/v1/tasks/:id`

**リクエスト**

```json
{
  "title": "スーパーに買い物に行く",
  "description": "牛乳、パン、卵を買う",
  "status": "doing",
  "priority": "high",
  "dueDate": "2026-03-21"
}
```

**レスポンス** — `200 OK`

```json
{
  "message": "Task updated successfully",
  "task": {
    "id": 101,
    "title": "スーパーに買い物に行く",
    "description": "牛乳、パン、卵を買う",
    "status": "doing",
    "priority": "high",
    "dueDate": "2026-03-21",
    "createdAt": "2026-03-19T10:30:00Z",
    "updatedAt": "2026-03-19T11:00:00Z"
  }
}
```

#### 9) タスク部分更新

`PATCH /api/v1/tasks/:id`

これは「状態だけ変えたい」時に便利です。

**リクエスト例**

```json
{
  "status": "done"
}
```

**レスポンス** — `200 OK`

```json
{
  "message": "Task updated successfully",
  "task": {
    "id": 101,
    "status": "done",
    "updatedAt": "2026-03-19T11:10:00Z"
  }
}
```

#### 10) タスク削除

`DELETE /api/v1/tasks/:id`

**レスポンス** — `200 OK`

```json
{
  "message": "Task deleted successfully"
}
```

---

## 6. エラーレスポンス仕様

APIは成功時だけでなく、失敗時も統一した形にすると使いやすいです。

### 基本形

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力内容に誤りがあります",
    "details": [
      {
        "field": "title",
        "message": "title is required"
      }
    ]
  }
}
```

### よくあるエラーコード

#### 400 Bad Request — 入力不正

```json
{
  "error": {
    "code": "BAD_REQUEST",
    "message": "不正なリクエストです"
  }
}
```

#### 401 Unauthorized — 未認証

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "認証が必要です"
  }
}
```

#### 403 Forbidden — 権限なし

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "このタスクにアクセスする権限がありません"
  }
}
```

#### 404 Not Found — 対象なし

```json
{
  "error": {
    "code": "TASK_NOT_FOUND",
    "message": "指定されたタスクは存在しません"
  }
}
```

#### 409 Conflict — 重複

```json
{
  "error": {
    "code": "EMAIL_ALREADY_EXISTS",
    "message": "このメールアドレスはすでに登録されています"
  }
}
```

#### 500 Internal Server Error — サーバーエラー

```json
{
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "サーバー内部でエラーが発生しました"
  }
}
```

---

## 7. 認証・認可の考え方

### 認証

- ログイン時にJWT発行
- 保護されたAPIではトークン検証

### 認可

とても大事なのは、**自分のタスクしか触れないこと**です。

例えば:

```
GET    /tasks/101
PUT    /tasks/101
DELETE /tasks/101
```

このとき、DB検索は単に `id=101` ではなく、  
**`id=101 AND userId=ログイン中ユーザーID`** の条件で探すべきです。

> ⚠️ これを忘れると、他人のタスクを見られる危険があります。

---

## 8. 推奨HTTPステータスコード

| コード                      | 意味                 |
| --------------------------- | -------------------- |
| `200 OK`                    | 取得・更新・削除成功 |
| `201 Created`               | 作成成功             |
| `400 Bad Request`           | 入力不正             |
| `401 Unauthorized`          | 未ログイン           |
| `403 Forbidden`             | 権限なし             |
| `404 Not Found`             | 対象が存在しない     |
| `409 Conflict`              | 重複                 |
| `500 Internal Server Error` | サーバー障害         |

---

## 9. 初学者向けのDBテーブル設計例

### users テーブル

| カラム名        | 型           | 制約             |
| --------------- | ------------ | ---------------- |
| `id`            | bigint       | PK               |
| `name`          | varchar(50)  | NOT NULL         |
| `email`         | varchar(255) | NOT NULL, UNIQUE |
| `password_hash` | varchar(255) | NOT NULL         |
| `created_at`    | datetime     | NOT NULL         |
| `updated_at`    | datetime     | NOT NULL         |

### tasks テーブル

| カラム名      | 型           | 制約                   |
| ------------- | ------------ | ---------------------- |
| `id`          | bigint       | PK                     |
| `user_id`     | bigint       | FK(users.id), NOT NULL |
| `title`       | varchar(100) | NOT NULL               |
| `description` | text         | NULL                   |
| `status`      | varchar(20)  | NOT NULL               |
| `priority`    | varchar(20)  | NOT NULL               |
| `due_date`    | date         | NULL                   |
| `created_at`  | datetime     | NOT NULL               |
| `updated_at`  | datetime     | NOT NULL               |

---

## 10. API利用の流れ

### 例: タスク作成までの流れ

```
1. ユーザー登録
   POST /api/v1/auth/register

2. ログイン
   POST /api/v1/auth/login
   → JWT取得

3. タスク作成
   POST /api/v1/tasks
   Authorization: Bearer <token>

4. タスク一覧表示
   GET /api/v1/tasks
   Authorization: Bearer <token>

5. タスク完了
   PATCH /api/v1/tasks/101
   Authorization: Bearer <token>
   { "status": "done" }
```

---

## 11. 初学者向けに特におすすめの実装ルール

設計をシンプルに保つため、次のルールがおすすめです。

### ルール1: レスポンス形式を統一する

たとえば成功時は以下のどちらかに揃える。

**パターンA**

```json
{
  "message": "success",
  "data": {}
}
```

**パターンB**

```json
{
  "task": {}
}
```

初心者には **`data` に統一** の方が拡張しやすいです。

```json
{
  "message": "Task created successfully",
  "data": {
    "id": 101,
    "title": "買い物に行く"
  }
}
```

### ルール2: 命名を統一する

- URLは複数形: `/tasks`
- JSONはキャメルケース: `dueDate`
- DBはスネークケース: `due_date`

### ルール3: いきなり機能を増やしすぎない

最初は不要です:

- サブタスク
- 通知
- ファイル添付
- タグ
- チーム共有
- リアルタイム同期

> まずは **CRUD + 認証** を完成させる方が重要です。

---

## 12. 最小API仕様まとめ

### 認証

```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
```

### ユーザー

```
GET /api/v1/users/me
```

### タスク

```
POST   /api/v1/tasks
GET    /api/v1/tasks
GET    /api/v1/tasks/:id
PUT    /api/v1/tasks/:id
PATCH  /api/v1/tasks/:id
DELETE /api/v1/tasks/:id
```

---

## 13. さらに良くする拡張案

将来の拡張としては、次が自然です。

- **タグ機能** — `GET /tasks?tag=study`
- **並び替え** — `GET /tasks?sortBy=dueDate&order=asc`
- **ソフトデリート** — 削除ではなく `deletedAt` を持つ
- **リフレッシュトークン**
- **OpenAPI（Swagger）化**
- **カテゴリ機能**
- **サブタスク機能**

---

## 14. おすすめの技術構成例

初学者向けなら次の組み合わせが扱いやすいです。

### 例1

| レイヤー     | 技術                |
| ------------ | ------------------- |
| フロント     | React               |
| バックエンド | Node.js + Express   |
| DB           | MySQL or PostgreSQL |
| 認証         | JWT                 |

### 例2

| レイヤー     | 技術                         |
| ------------ | ---------------------------- |
| フロント     | Next.js                      |
| バックエンド | Next.js API Routes / Express |
| DB           | PostgreSQL                   |
| ORM          | Prisma                       |

---

## 15. 実務っぽいAPI仕様の完成版サンプル

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
GET    /api/v1/users/me

POST   /api/v1/tasks
GET    /api/v1/tasks
GET    /api/v1/tasks/:id
PUT    /api/v1/tasks/:id
PATCH  /api/v1/tasks/:id
DELETE /api/v1/tasks/:id
```

---

## 16. 設計の考え方を一言でいうと

> このアプリのAPI設計は、料理でいうと  
> **「まずは包丁・まな板・鍋だけ揃える」** 感覚です。

最初から豪華な調理器具を全部揃えるより、まずは最低限の道具でちゃんと料理できることが大事です。

APIも同じで、最初は次の基本5点をきれいに作るのが一番重要です:

1. 認証
2. 一覧取得
3. 作成
4. 更新
5. 削除

---

## 17. まとめ

### このAPI仕様の特徴

- 初学者でも理解しやすい
- RESTの基本を学べる
- 認証とCRUDを一通り実装できる
- 今後の拡張もしやすい

### 最初に実装すべき優先順位

1. ユーザー登録
2. ログイン
3. タスク作成
4. タスク一覧
5. タスク更新
6. タスク削除
7. 絞り込み・ページネーション

---

> 必要なら次に、「このAPI仕様を Swagger（OpenAPI）のYAMLで書く」または「Express / Node.js でそのまま実装できるAPI設計書に落とす」形まで続けて作れます。
