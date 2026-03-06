### 1. データベース設計案 (Supabase / PostgreSQL)

PostgreSQLの拡張機能である「PostGIS」を利用して、位置情報を効率的に扱う設計にします。

#### `spots` テーブル (界隈)

各コミュニティの拠点を定義します。

* `id`: uuid (PK)
* `name`: text (例: "駒沢公園ランナー界隈")
* `location`: geography(POINT) (緯度経度・PostGIS用)
* `radius_meters`: int (チェックイン判定の半径)
* `leader_id`: uuid (FK -> profiles.id)
* `description`: text
* `created_at`: timestamp

#### `profiles` テーブル (ユーザー情報)

* `id`: uuid (PK)
* `username`: text
* `avatar_url`: text
* `bio`: text
* `is_leader`: boolean

#### `check_ins` テーブル (活動記録)

* `id`: uuid (PK)
* `user_id`: uuid (FK)
* `spot_id`: uuid (FK)
* `check_in_at`: timestamp
* `check_out_at`: timestamp
* `status`: text (例: "running", "workout")

#### `contents` テーブル (界隈ノート/CMS)

* `id`: uuid (PK)
* `spot_id`: uuid (FK)
* `author_id`: uuid (FK)
* `title`: text
* `body_json`: jsonb (Tiptapの出力データ)
* `is_premium`: boolean (ペイウォール用)
* `price`: int
