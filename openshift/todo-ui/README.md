# Todo UI - OpenShift Deployment Guide

Todo UI アプリケーションをOpenShiftにデプロイするためのリソースとスクリプトです。

## 概要

Todo UIは、QuarkusまたはSpring BootのバックエンドTodo APIと連携するWebベースのUIアプリケーションです。このディレクトリには、OpenShift環境にデプロイするための全リソースが含まれています。

### 特徴

- **Standard Deploymentのみ**: 常時稼働のDeploymentとしてデプロイ（Serverlessデプロイはサポートしていません）
- **バックエンド連携**: QuarkusまたはSpring BootのTodo APIと連携
- **自動ヘルスチェック**: バックエンドのタイプに応じた適切なヘルスチェック
- **GitHubからビルド**: ソースコードをGitHubから取得してOpenShift上でビルド

## 前提条件

### 必須要件

1. **OpenShiftクラスターへのアクセス**
   - OpenShift 4.x クラスター
   - `oc` コマンドでログイン済み

2. **バックエンドTodo API**
   - QuarkusまたはSpring BootのTodo APIがデプロイ済み
   - RouteのURLが取得できている状態

3. **権限**
   - プロジェクト/ネームスペースの作成権限
   - BuildConfig、ImageStream、Deploymentの作成権限

### 確認方法

```bash
# OpenShiftにログインしているか確認
oc whoami
oc whoami --show-server

# バックエンドAPIのRoute URLを取得
# Quarkusの場合
oc get route quarkus-todo-jvm -n demo-apps -o jsonpath='{.spec.host}'

# Spring Bootの場合
oc get route spring-todo-jvm -n demo-apps -o jsonpath='{.spec.host}'
```

## ディレクトリ構成

```
openshift/todo-ui/
├── README.md           # このファイル
├── Dockerfile          # マルチステージビルド用Dockerfile
├── deployment.yaml     # Deploymentマニフェスト
├── service.yaml        # Serviceマニフェスト
├── route.yaml          # Routeマニフェスト
└── deploy.sh           # デプロイスクリプト
```

## デプロイ方法

### 基本的な使い方

deploy.shスクリプトは、2つの必須引数を受け取ります。

```bash
./deploy.sh <BACKEND_URL> <BACKEND_TYPE>
```

**引数:**
- `BACKEND_URL`: バックエンドTodo APIのRoute URL（必須）
- `BACKEND_TYPE`: バックエンドのタイプ `quarkus` または `spring`（必須）

### Quarkusバックエンドと連携

```bash
cd openshift/todo-ui

# バックエンドのURLを取得
BACKEND_URL=https://$(oc get route quarkus-todo-jvm -n demo-apps -o jsonpath='{.spec.host}')

# デプロイ実行
./deploy.sh $BACKEND_URL quarkus
```

### Spring Bootバックエンドと連携

```bash
cd openshift/todo-ui

# バックエンドのURLを取得
BACKEND_URL=https://$(oc get route spring-todo-jvm -n demo-apps -o jsonpath='{.spec.host}')

# デプロイ実行
./deploy.sh $BACKEND_URL spring
```

### 環境変数のカスタマイズ

デプロイスクリプトは、以下の環境変数をサポートしています。

```bash
# ネームスペース名（デフォルト: demo-apps）
export OPENSHIFT_NAMESPACE=my-namespace

# Gitリポジトリ（デフォルト: https://github.com/kamorisan/quarkus-spring-todo.git）
export GIT_REPO=https://github.com/your-repo.git

# Gitブランチ（デフォルト: main）
export GIT_BRANCH=develop

# デプロイ実行
./deploy.sh $BACKEND_URL quarkus
```

## デプロイメント詳細

### リソース設定

| リソース | Request | Limit |
|---------|---------|-------|
| Memory  | 256Mi   | 512Mi |
| CPU     | 100m    | 500m  |

### 環境変数

Todo UIは、以下の環境変数を使用します（deployment.yamlで自動設定されます）。

| 環境変数 | 説明 | 設定方法 |
|---------|------|---------|
| `BACKEND_URL` | バックエンドAPIのURL | デプロイスクリプトの第1引数 |
| `BACKEND_TYPE` | バックエンドのタイプ（quarkus/spring） | デプロイスクリプトの第2引数 |
| `QUARKUS_HTTP_PORT` | アプリケーションのポート | 8080（固定） |
| `QUARKUS_LOG_LEVEL` | ログレベル | INFO（固定） |

### バックエンドタイプによる違い

Todo UIは、バックエンドのタイプに応じて異なるヘルスチェックエンドポイントを使用します。

| バックエンド | ヘルスチェックエンドポイント |
|------------|---------------------------|
| Quarkus | `/q/health/ready` |
| Spring Boot | `/actuator/health/readiness` |

## デプロイ後の確認

### Route URLの取得

```bash
# デフォルトネームスペースの場合
oc get route todo-ui -n demo-apps -o jsonpath='{.spec.host}'

# カスタムネームスペースの場合
oc get route todo-ui -n <your-namespace> -o jsonpath='{.spec.host}'
```

### ブラウザでアクセス

```bash
ROUTE_URL=$(oc get route todo-ui -n demo-apps -o jsonpath='{.spec.host}')
echo "https://$ROUTE_URL"

# ブラウザで開く
open https://$ROUTE_URL  # macOS
```

### ヘルスチェック

```bash
ROUTE_URL=$(oc get route todo-ui -n demo-apps -o jsonpath='{.spec.host}')

# Todo UI自体のヘルスチェック
curl https://$ROUTE_URL/q/health/ready

# バックエンド情報の確認
curl https://$ROUTE_URL/api/backend/info

# バックエンドのヘルスチェック（プロキシ経由）
curl https://$ROUTE_URL/api/backend/health
```

### API テスト

```bash
ROUTE_URL=$(oc get route todo-ui -n demo-apps -o jsonpath='{.spec.host}')

# Todoリストの取得
curl https://$ROUTE_URL/api/todos

# Todoの作成
curl -X POST https://$ROUTE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Test from UI",
    "description": "Testing Todo UI on OpenShift",
    "completed": false
  }'
```

## 監視とログ

### Podの確認

```bash
# Podの一覧
oc get pods -n demo-apps -l app=todo-ui

# Pod詳細
oc describe pod <pod-name> -n demo-apps
```

### ログの確認

```bash
# リアルタイムログ
oc logs -f -l app=todo-ui -n demo-apps

# 最新100行
oc logs -l app=todo-ui -n demo-apps --tail=100
```

### リソース使用状況

```bash
# CPU/メモリ使用量
oc adm top pod -n demo-apps -l app=todo-ui
```

### Deployment詳細

```bash
# Deploymentの状態確認
oc get deployment todo-ui -n demo-apps

# Deployment詳細
oc describe deployment todo-ui -n demo-apps

# Serviceの確認
oc get service todo-ui -n demo-apps

# Routeの確認
oc get route todo-ui -n demo-apps
```

## スケーリング

```bash
# レプリカ数を3に増やす
oc scale deployment/todo-ui -n demo-apps --replicas=3

# 確認
oc get pods -n demo-apps -l app=todo-ui
```

## トラブルシューティング

### ビルドが失敗する場合

```bash
# ビルドログの確認
oc logs -f bc/todo-ui -n demo-apps

# ビルドの再実行
oc start-build todo-ui -n demo-apps --follow
```

### DeploymentがReadyにならない場合

```bash
# Deploymentの状態確認
oc get deployment todo-ui -n demo-apps
oc describe deployment todo-ui -n demo-apps

# Podの状態確認
oc get pods -n demo-apps -l app=todo-ui
oc describe pod <pod-name> -n demo-apps

# ログ確認
oc logs <pod-name> -n demo-apps

# イベント確認
oc get events -n demo-apps --sort-by='.lastTimestamp' | tail -20
```

### バックエンドに接続できない場合

1. **環境変数の確認**
   ```bash
   oc get deployment todo-ui -n demo-apps -o yaml | grep -A 5 "env:"
   ```

2. **BACKEND_URLが正しいか確認**
   ```bash
   # デプロイ時に指定したURLが正しいか確認
   # 間違っている場合は再デプロイ
   ./deploy.sh <correct-backend-url> <backend-type>
   ```

3. **バックエンドAPIが稼働しているか確認**
   ```bash
   # Quarkusの場合
   curl https://<backend-url>/q/health/ready

   # Spring Bootの場合
   curl https://<backend-url>/actuator/health/readiness
   ```

### UIが表示されない場合

1. **Routeの確認**
   ```bash
   oc get route todo-ui -n demo-apps
   ```

2. **Podのログを確認**
   ```bash
   oc logs -f -l app=todo-ui -n demo-apps
   ```

3. **ブラウザのコンソールでエラーを確認**
   - F12で開発者ツールを開く
   - ConsoleタブとNetworkタブでエラーを確認

## 更新とメンテナンス

### アプリケーションの更新

GitHubリポジトリのコードを更新した後、再ビルド・再デプロイします。

```bash
# ビルドの再実行
oc start-build todo-ui -n demo-apps --follow --wait

# Deploymentを再起動（新しいイメージを使用）
oc rollout restart deployment/todo-ui -n demo-apps
oc rollout status deployment/todo-ui -n demo-apps
```

### バックエンドURLの変更

バックエンドのURLやタイプを変更する場合は、再デプロイします。

```bash
# 新しいバックエンドURLとタイプで再デプロイ
./deploy.sh <new-backend-url> <new-backend-type>
```

または、環境変数を直接更新します。

```bash
# 環境変数の更新
oc set env deployment/todo-ui -n demo-apps \
  BACKEND_URL=<new-backend-url> \
  BACKEND_TYPE=<new-backend-type>

# 自動的に再起動されます
oc rollout status deployment/todo-ui -n demo-apps
```

## クリーンアップ

### リソースの削除

```bash
# 個別削除
oc delete deployment todo-ui -n demo-apps
oc delete service todo-ui -n demo-apps
oc delete route todo-ui -n demo-apps
oc delete bc todo-ui -n demo-apps
oc delete is todo-ui -n demo-apps

# または、ネームスペースごと削除
oc delete namespace demo-apps
```

## アーキテクチャ

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────────────────┐
│   OpenShift Route (TLS)     │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│   Todo UI Service           │
│   (ClusterIP)               │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│   Todo UI Pod               │
│   ┌──────────────────────┐  │
│   │  Quarkus App         │  │
│   │  - Static UI         │  │
│   │  - REST Proxy        │  │
│   │  - Health Proxy      │  │
│   └──────────────────────┘  │
└──────────┬──────────────────┘
           │ REST Client
           │ BACKEND_URL
           ▼
┌─────────────────────────────┐
│   Backend Todo API          │
│   (Quarkus or Spring Boot)  │
└─────────────────────────────┘
```

## セキュリティ

- **非rootユーザー**: コンテナはユーザーID 185で実行
- **TLS終端**: RouteでEdge TLS終端を使用
- **最小権限**: 必要最小限のリソースとパーミッション

## パフォーマンス

### 起動時間

- コールドスタート: 数秒
- ウォームスタート: 1秒未満

### メモリ使用量

- アイドル時: 約200MB
- 負荷時: 約300-400MB

### 推奨設定

- **開発/テスト環境**: replica=1, 256Mi/512Mi
- **本番環境**: replica=2-3, 512Mi/1Gi, HPA有効化

## 参考情報

### 関連ドキュメント

- [Todo UI アプリケーション README](../../todo-ui/README.md)
- [OpenShift デプロイメントガイド](../README.md)

### 関連リソース

- [Red Hat OpenShift Documentation](https://docs.openshift.com/)
- [Quarkus Official Site](https://quarkus.io/)
- [Quarkus on OpenShift](https://quarkus.io/guides/deploying-to-openshift)

## ライセンス

このプロジェクトのライセンスについては、リポジトリのルートディレクトリを参照してください。
