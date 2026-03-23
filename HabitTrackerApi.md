# 習慣トラッカー バックエンドAPI設計書

## 1. 基本情報

| 項目           | 内容                               |
| -------------- | ---------------------------------- |
| ベースURL      | `https://api.example.com/v1`       |
| 認証方式       | Bearer Token（JWT）                |
| レスポンス形式 | JSON                               |
| 文字コード     | UTF-8                              |
| 日付形式       | ISO 8601（`2026-03-23T00:00:00Z`） |
| 日付のみ       | `YYYY-MM-DD`                       |

---

## 2. 共通仕様

### リクエストヘッダー

```
Content-Type: application/json
Authorization: Bearer <token>
```

### 共通レスポンス構造

**成功時**

```json
{
  "status": "success",
  "data": { ... }
}
```

**エラー時**

```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "タイトルは必須です"
  }
}
```

### 共通エラーコード

| HTTPステータス | コード             | 説明                                     |
| -------------- | ------------------ | ---------------------------------------- |
| 400            | `VALIDATION_ERROR` | バリデーションエラー                     |
| 401            | `UNAUTHORIZED`     | 未認証                                   |
| 403            | `FORBIDDEN`        | 権限なし                                 |
| 404            | `NOT_FOUND`        | リソースが見つからない                   |
| 409            | `CONFLICT`         | 重複（同日に同じ習慣のログが既に存在等） |
| 429            | `RATE_LIMIT`       | レート制限超過                           |
| 500            | `INTERNAL_ERROR`   | サーバーエラー                           |

---

## 3. 認証 API

### POST `/auth/register` — ユーザー登録

**リクエスト**

```json
{
  "name": "田中太郎",
  "email": "tanaka@example.com",
  "password": "SecurePass123!"
}
```

**レスポンス** `201 Created`

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "usr_abc123",
      "name": "田中太郎",
      "email": "tanaka@example.com",
      "created_at": "2026-03-23T10:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**バリデーション**

- `name`: 1〜50文字
- `email`: 有効なメール形式、未登録であること
- `password`: 8文字以上、英字・数字を含む

---

### POST `/auth/login` — ログイン

**リクエスト**

```json
{
  "email": "tanaka@example.com",
  "password": "SecurePass123!"
}
```

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "usr_abc123",
      "name": "田中太郎",
      "email": "tanaka@example.com"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### POST `/auth/google` — Googleログイン

**リクエスト**

```json
{
  "id_token": "<Google ID Token>"
}
```

**レスポンス**: 登録・ログインと同じ構造

---

### POST `/auth/logout` — ログアウト

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "message": "ログアウトしました"
  }
}
```

---

### GET `/auth/me` — ログインユーザー情報取得

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "id": "usr_abc123",
    "name": "田中太郎",
    "email": "tanaka@example.com",
    "created_at": "2026-03-23T10:00:00Z"
  }
}
```

---

## 4. 習慣 API

### GET `/habits` — 習慣一覧取得

**クエリパラメータ**

| パラメータ | 型     | 必須 | 説明               |
| ---------- | ------ | ---- | ------------------ |
| `category` | string | ×    | カテゴリでフィルタ |

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": [
    {
      "id": "hab_001",
      "title": "ランニング",
      "description": "毎朝30分走る",
      "color": "#FF6B6B",
      "category": "運動",
      "current_streak": 5,
      "best_streak": 14,
      "today_completed": true,
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-03-20T08:00:00Z"
    },
    {
      "id": "hab_002",
      "title": "読書",
      "description": "1日30ページ以上読む",
      "color": "#4ECDC4",
      "category": "学習",
      "current_streak": 12,
      "best_streak": 30,
      "today_completed": false,
      "created_at": "2026-01-15T00:00:00Z",
      "updated_at": "2026-03-22T20:00:00Z"
    }
  ]
}
```

---

### POST `/habits` — 習慣を追加

**リクエスト**

```json
{
  "title": "英語学習",
  "description": "Duolingoを毎日1レッスン",
  "color": "#45B7D1",
  "category": "学習"
}
```

**レスポンス** `201 Created`

```json
{
  "status": "success",
  "data": {
    "id": "hab_003",
    "title": "英語学習",
    "description": "Duolingoを毎日1レッスン",
    "color": "#45B7D1",
    "category": "学習",
    "current_streak": 0,
    "best_streak": 0,
    "today_completed": false,
    "created_at": "2026-03-23T10:00:00Z",
    "updated_at": "2026-03-23T10:00:00Z"
  }
}
```

**バリデーション**

- `title`: 必須、1〜100文字
- `description`: 任意、最大500文字
- `color`: 任意、HEXカラー形式（デフォルト `#6C757D`）
- `category`: 任意、最大50文字

---

### GET `/habits/:habitId` — 習慣の詳細取得

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "id": "hab_001",
    "title": "ランニング",
    "description": "毎朝30分走る",
    "color": "#FF6B6B",
    "category": "運動",
    "current_streak": 5,
    "best_streak": 14,
    "total_completions": 45,
    "today_completed": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-03-20T08:00:00Z"
  }
}
```

---

### PATCH `/habits/:habitId` — 習慣を編集

**リクエスト**（変更したいフィールドのみ）

```json
{
  "title": "朝ラン",
  "color": "#E74C3C"
}
```

**レスポンス** `200 OK`: 更新後の習慣オブジェクト

---

### DELETE `/habits/:habitId` — 習慣を削除

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "message": "習慣を削除しました"
  }
}
```

> 関連する `habit_logs` も全て削除される（カスケード削除）

---

## 5. 習慣ログ API

### POST `/habits/:habitId/logs` — 達成記録を追加

**リクエスト**

```json
{
  "date": "2026-03-23",
  "status": "completed",
  "note": "雨だったけど走れた！"
}
```

**レスポンス** `201 Created`

```json
{
  "status": "success",
  "data": {
    "id": "log_001",
    "habit_id": "hab_001",
    "date": "2026-03-23",
    "status": "completed",
    "note": "雨だったけど走れた！",
    "created_at": "2026-03-23T07:30:00Z"
  }
}
```

**バリデーション**

- `date`: 必須、`YYYY-MM-DD` 形式、未来日は不可
- `status`: 必須、`completed` または `skipped`
- `note`: 任意、最大500文字
- 同一習慣・同一日付の重複登録は `409 CONFLICT`

---

### PATCH `/habits/:habitId/logs/:logId` — 記録を更新

**リクエスト**

```json
{
  "status": "skipped",
  "note": "体調不良のためスキップ"
}
```

**レスポンス** `200 OK`: 更新後のログオブジェクト

---

### DELETE `/habits/:habitId/logs/:logId` — 記録を削除

**レスポンス** `200 OK`

---

### GET `/habits/:habitId/logs` — ログ一覧取得（カレンダー用）

**クエリパラメータ**

| パラメータ | 型      | 必須 | 説明        |
| ---------- | ------- | ---- | ----------- |
| `year`     | integer | ○    | 年          |
| `month`    | integer | ○    | 月（1〜12） |

**リクエスト例**

```
GET /habits/hab_001/logs?year=2026&month=3
```

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "year": 2026,
    "month": 3,
    "logs": [
      { "date": "2026-03-01", "status": "completed", "note": null },
      { "date": "2026-03-02", "status": "completed", "note": "調子良かった" },
      { "date": "2026-03-03", "status": "skipped", "note": "出張のため" },
      { "date": "2026-03-04", "status": "completed", "note": null }
    ],
    "summary": {
      "total_days": 23,
      "completed": 18,
      "skipped": 3,
      "no_record": 2,
      "completion_rate": 78.3
    }
  }
}
```

---

## 6. ダッシュボード API

### GET `/dashboard` — 今日のダッシュボード

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "date": "2026-03-23",
    "habits": [
      {
        "id": "hab_001",
        "title": "ランニング",
        "color": "#FF6B6B",
        "category": "運動",
        "today_completed": true,
        "current_streak": 5
      },
      {
        "id": "hab_002",
        "title": "読書",
        "color": "#4ECDC4",
        "category": "学習",
        "today_completed": false,
        "current_streak": 12
      }
    ],
    "today_summary": {
      "total_habits": 5,
      "completed": 3,
      "completion_rate": 60.0
    },
    "month_summary": {
      "total_days_elapsed": 23,
      "avg_completion_rate": 72.5
    }
  }
}
```

---

### POST `/dashboard/quick-log` — ワンタップ達成記録

ダッシュボードからの簡易記録用。ボタン1つで今日の達成を記録する。

**リクエスト**

```json
{
  "habit_id": "hab_001"
}
```

**レスポンス** `201 Created`

```json
{
  "status": "success",
  "data": {
    "id": "log_050",
    "habit_id": "hab_001",
    "date": "2026-03-23",
    "status": "completed",
    "note": null,
    "created_at": "2026-03-23T07:30:00Z"
  }
}
```

> 既に記録済みの場合は `409 CONFLICT` を返す。トグル動作にしたい場合は、既存ログを削除して `200 OK` を返す設計も検討可能。

---

## 7. レポート API

### GET `/reports/monthly` — 月次レポート

**クエリパラメータ**

| パラメータ | 型      | 必須 | 説明        |
| ---------- | ------- | ---- | ----------- |
| `year`     | integer | ○    | 年          |
| `month`    | integer | ○    | 月（1〜12） |

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "year": 2026,
    "month": 3,
    "overall": {
      "total_completions": 85,
      "avg_completion_rate": 72.5,
      "best_streak": 14,
      "best_streak_habit": {
        "id": "hab_002",
        "title": "読書"
      }
    },
    "per_habit": [
      {
        "habit_id": "hab_001",
        "title": "ランニング",
        "color": "#FF6B6B",
        "completions": 20,
        "completion_rate": 87.0,
        "best_streak": 10,
        "current_streak": 5
      },
      {
        "habit_id": "hab_002",
        "title": "読書",
        "color": "#4ECDC4",
        "completions": 22,
        "completion_rate": 95.7,
        "best_streak": 14,
        "current_streak": 12
      }
    ],
    "by_day_of_week": {
      "mon": 82.0,
      "tue": 78.0,
      "wed": 75.0,
      "thu": 80.0,
      "fri": 65.0,
      "sat": 60.0,
      "sun": 55.0
    },
    "heatmap": [
      { "date": "2026-03-01", "completion_rate": 100.0 },
      { "date": "2026-03-02", "completion_rate": 80.0 },
      { "date": "2026-03-03", "completion_rate": 40.0 }
    ],
    "vs_previous_month": {
      "completion_rate_diff": +5.2,
      "total_completions_diff": +12
    }
  }
}
```

---

### GET `/reports/weekly` — 週次レポート

**クエリパラメータ**

| パラメータ | 型     | 必須 | 説明                                 |
| ---------- | ------ | ---- | ------------------------------------ |
| `date`     | string | ×    | 週の起点日（デフォルト: 今週の月曜） |

**レスポンス** `200 OK`

```json
{
  "status": "success",
  "data": {
    "week_start": "2026-03-16",
    "week_end": "2026-03-22",
    "overall_completion_rate": 75.0,
    "daily_breakdown": [
      { "date": "2026-03-16", "completed": 4, "total": 5, "rate": 80.0 },
      { "date": "2026-03-17", "completed": 3, "total": 5, "rate": 60.0 }
    ],
    "per_habit": [
      {
        "habit_id": "hab_001",
        "title": "ランニング",
        "completions": 5,
        "total": 7,
        "rate": 71.4
      }
    ]
  }
}
```

---

## 8. 連続達成日数 計算ロジック

連続日数はAPI側で計算してレスポンスに含める。計算ルールは以下の通り。

```
current_streak の計算:
  1. 今日から過去に向かって、連続で status = "completed" の日数を数える
  2. 今日がまだ未記録の場合は、昨日から遡って数える
  3. 途中に "skipped" や記録なしの日があった時点で打ち切り

best_streak の計算:
  1. 全ての記録を日付順に走査
  2. 連続達成の最長区間を返す
```

**エッジケースの考慮**

- 習慣登録前の日付は連続日数に含めない
- 未来の日付は無視する
- `skipped` は連続を途切れさせる（達成とは見なさない）

---

## 9. API一覧（まとめ）

| メソッド | パス                           | 説明             | 認証 |
| -------- | ------------------------------ | ---------------- | ---- |
| POST     | `/auth/register`               | ユーザー登録     | ×    |
| POST     | `/auth/login`                  | ログイン         | ×    |
| POST     | `/auth/google`                 | Googleログイン   | ×    |
| POST     | `/auth/logout`                 | ログアウト       | ○    |
| GET      | `/auth/me`                     | ユーザー情報取得 | ○    |
| GET      | `/habits`                      | 習慣一覧取得     | ○    |
| POST     | `/habits`                      | 習慣追加         | ○    |
| GET      | `/habits/:habitId`             | 習慣詳細取得     | ○    |
| PATCH    | `/habits/:habitId`             | 習慣編集         | ○    |
| DELETE   | `/habits/:habitId`             | 習慣削除         | ○    |
| GET      | `/habits/:habitId/logs`        | ログ一覧取得     | ○    |
| POST     | `/habits/:habitId/logs`        | 達成記録追加     | ○    |
| PATCH    | `/habits/:habitId/logs/:logId` | 記録更新         | ○    |
| DELETE   | `/habits/:habitId/logs/:logId` | 記録削除         | ○    |
| GET      | `/dashboard`                   | ダッシュボード   | ○    |
| POST     | `/dashboard/quick-log`         | ワンタップ記録   | ○    |
| GET      | `/reports/monthly`             | 月次レポート     | ○    |
| GET      | `/reports/weekly`              | 週次レポート     | ○    |

---

## 10. 今後の拡張候補

| 機能               | エンドポイント案                | 説明                         |
| ------------------ | ------------------------------- | ---------------------------- |
| リマインダー設定   | `PUT /habits/:habitId/reminder` | 通知時刻・曜日の設定         |
| プロフィール更新   | `PATCH /users/me`               | 名前・アバター変更           |
| パスワード変更     | `POST /auth/change-password`    | 現パスワード + 新パスワード  |
| 習慣のアーカイブ   | `POST /habits/:habitId/archive` | 削除せず非表示にする         |
| 年次レポート       | `GET /reports/yearly`           | 年間の振り返りデータ         |
| データエクスポート | `GET /export`                   | CSV / JSON形式でダウンロード |
