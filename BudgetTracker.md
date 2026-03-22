# 家計簿アプリ API 仕様書（簡素版）

## 概要

最低限の機能に絞った家計簿アプリのAPI仕様です。

### 機能一覧

- ログイン
- 支出／収入の登録
- 一覧表示
- 削除
- 月次集計

> カテゴリ管理・予算管理・編集機能は対象外とし、カテゴリは固定値で運用します。

---

## データモデル

### ユーザー

```json
{
  "id": 1,
  "name": "Taro",
  "email": "taro@example.com",
  "passwordHash": "..."
}
```

### 家計簿レコード

```json
{
  "id": 1,
  "userId": 1,
  "type": "expense",
  "category": "food",
  "amount": 1200,
  "date": "2026-03-22",
  "memo": "昼ごはん"
}
```

---

## 固定カテゴリ

フロントエンドとバックエンドで共通定義し、カテゴリAPIは不要とします。

### 支出（expense）

| キー        | 表示名 |
| ----------- | ------ |
| `food`      | 食費   |
| `transport` | 交通費 |
| `shopping`  | 買い物 |
| `other`     | その他 |

### 収入（income）

| キー     | 表示名   |
| -------- | -------- |
| `salary` | 給料     |
| `bonus`  | ボーナス |
| `other`  | その他   |

---

## 認証方式

- ログイン時に JWT を返却
- 以後のリクエストは `Authorization: Bearer <token>` ヘッダーを付与

---

## API エンドポイント一覧

| メソッド | パス                         | 説明         |
| -------- | ---------------------------- | ------------ |
| `POST`   | `/api/login`                 | ログイン     |
| `GET`    | `/api/records`               | 一覧取得     |
| `POST`   | `/api/records`               | レコード登録 |
| `DELETE` | `/api/records/:id`           | レコード削除 |
| `GET`    | `/api/summary?month=YYYY-MM` | 月次集計     |

---

## API 詳細

### 1. ログイン

`POST /api/login`

#### Request

```json
{
  "email": "taro@example.com",
  "password": "password123"
}
```

#### Response

```json
{
  "token": "jwt-token",
  "user": {
    "id": 1,
    "name": "Taro",
    "email": "taro@example.com"
  }
}
```

---

### 2. 一覧取得

`GET /api/records`

#### Query パラメータ

| パラメータ | 型       | 説明                    |
| ---------- | -------- | ----------------------- |
| `month`    | `string` | 対象月（例: `2026-03`） |

#### Response

```json
{
  "records": [
    {
      "id": 1,
      "type": "expense",
      "category": "food",
      "amount": 1200,
      "date": "2026-03-22",
      "memo": "昼ごはん"
    },
    {
      "id": 2,
      "type": "income",
      "category": "salary",
      "amount": 300000,
      "date": "2026-03-25",
      "memo": "給料"
    }
  ]
}
```

---

### 3. レコード登録

`POST /api/records`

#### Request

```json
{
  "type": "expense",
  "category": "food",
  "amount": 1200,
  "date": "2026-03-22",
  "memo": "昼ごはん"
}
```

#### Response

```json
{
  "id": 1,
  "type": "expense",
  "category": "food",
  "amount": 1200,
  "date": "2026-03-22",
  "memo": "昼ごはん"
}
```

---

### 4. レコード削除

`DELETE /api/records/:id`

#### Response

```json
{
  "message": "deleted"
}
```

---

### 5. 月次集計

`GET /api/summary?month=2026-03`

#### Response

```json
{
  "month": "2026-03",
  "income": 300000,
  "expense": 45000,
  "balance": 255000
}
```

---

## バリデーションルール

| フィールド | ルール                    |
| ---------- | ------------------------- |
| `type`     | `income` または `expense` |
| `category` | 固定カテゴリのいずれか    |
| `amount`   | 1 以上の整数              |
| `date`     | `YYYY-MM-DD` 形式         |

---

## DB テーブル定義

### users

| カラム          | 型              | 説明               |
| --------------- | --------------- | ------------------ |
| `id`            | `INTEGER` (PK)  | ユーザーID         |
| `name`          | `TEXT`          | ユーザー名         |
| `email`         | `TEXT` (UNIQUE) | メールアドレス     |
| `password_hash` | `TEXT`          | パスワードハッシュ |

### records

| カラム     | 型             | 説明                 |
| ---------- | -------------- | -------------------- |
| `id`       | `INTEGER` (PK) | レコードID           |
| `user_id`  | `INTEGER` (FK) | ユーザーID           |
| `type`     | `TEXT`         | `income` / `expense` |
| `category` | `TEXT`         | 固定カテゴリ         |
| `amount`   | `INTEGER`      | 金額                 |
| `date`     | `TEXT`         | 日付（YYYY-MM-DD）   |
| `memo`     | `TEXT`         | メモ                 |
