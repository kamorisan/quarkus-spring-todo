# OpenShift Serverless Deployment

QuarkusとSpring Bootのアプリケーションを、OpenShift Serverless (Knative Serving) にデプロイするためのリソースとスクリプトです。

## 概要

このディレクトリには、3つの異なる構成でアプリケーションをデプロイするためのリソースが含まれています。

1. **Quarkus Native Image** - 超高速起動と最小メモリフットプリント
2. **Quarkus JVM** - 高速起動とバランスの取れたパフォーマンス
3. **Spring Boot JVM** - 標準的なSpring Bootアプリケーション

すべてのデプロイメントは、GitHubリポジトリ (`https://github.com/kamorisan/quarkus-spring-todo.git`) からソースコードを取得し、OpenShift上でビルドしてデプロイします。

## 前提条件

### 必須要件

1. **OpenShiftクラスターへのアクセス**
   - OpenShift 4.x クラスター
   - OpenShift Serverless (Knative Serving) がインストール済み

2. **CLIツール**
   - `oc` コマンド (OpenShift CLI)
   - OpenShiftクラスターにログイン済み

3. **権限**
   - プロジェクト/ネームスペースの作成権限
   - BuildConfig、ImageStream、Knative Serviceの作成権限

### 確認方法

```bash
# OpenShiftにログインしているか確認
oc whoami
oc whoami --show-server

# Knative Servingが利用可能か確認
oc api-resources | grep knative
```

## ディレクトリ構成

```
openshift/
├── README.md                    # このファイル
├── quarkus-native/              # Quarkus Native Image デプロイメント
│   ├── Dockerfile               # マルチステージビルド (GraalVM Native Image)
│   ├── knative-service.yaml     # Knative Service定義
│   └── deploy.sh                # デプロイスクリプト
├── quarkus-jvm/                 # Quarkus JVM デプロイメント
│   ├── Dockerfile               # マルチステージビルド (OpenJDK 21)
│   ├── knative-service.yaml     # Knative Service定義
│   └── deploy.sh                # デプロイスクリプト
└── spring-jvm/                  # Spring Boot JVM デプロイメント
    ├── Dockerfile               # マルチステージビルド (OpenJDK 21)
    ├── knative-service.yaml     # Knative Service定義
    └── deploy.sh                # デプロイスクリプト
```

## デプロイ方法

### 共通の環境変数

すべてのデプロイスクリプトで以下の環境変数をサポートしています。

```bash
# ネームスペース名 (デフォルト: demo-serverless)
export OPENSHIFT_NAMESPACE=demo-serverless

# Gitリポジトリ (デフォルト: https://github.com/kamorisan/quarkus-spring-todo.git)
export GIT_REPO=https://github.com/kamorisan/quarkus-spring-todo.git

# Gitブランチ (デフォルト: main)
export GIT_BRANCH=main
```

### 1. Quarkus Native Image のデプロイ

**特徴:**
- 超高速起動 (数ミリ秒)
- 最小メモリフットプリント (64-128 Mi)
- Scale-to-zero: 30秒後
- ビルド時間: 約10-15分 (Native Image コンパイル)

**デプロイ手順:**

```bash
cd openshift/quarkus-native
./deploy.sh
```

**リソース設定:**
- CPU: 50m (request) / 200m (limit)
- Memory: 64Mi (request) / 128Mi (limit)
- Auto-scaling: 0-10 pods

### 2. Quarkus JVM のデプロイ

**特徴:**
- 高速起動 (数秒)
- バランスの取れたメモリフットプリント (256-512 Mi)
- Scale-to-zero: 2分後
- ビルド時間: 約3-5分

**デプロイ手順:**

```bash
cd openshift/quarkus-jvm
./deploy.sh
```

**リソース設定:**
- CPU: 100m (request) / 500m (limit)
- Memory: 256Mi (request) / 512Mi (limit)
- Auto-scaling: 0-10 pods

### 3. Spring Boot JVM のデプロイ

**特徴:**
- 標準的な起動時間 (数十秒)
- 標準的なメモリフットプリント (384-768 Mi)
- Scale-to-zero: 2分後
- ビルド時間: 約3-5分

**デプロイ手順:**

```bash
cd openshift/spring-jvm
./deploy.sh
```

**リソース設定:**
- CPU: 100m (request) / 500m (limit)
- Memory: 384Mi (request) / 768Mi (limit)
- Auto-scaling: 0-10 pods

## デプロイスクリプトの動作

各 `deploy.sh` スクリプトは以下の処理を実行します。

1. **OpenShift接続確認** - `oc whoami` でログイン状態を確認
2. **ネームスペース作成** - 存在しない場合は作成
3. **ImageStream作成** - ビルドしたイメージを保存
4. **BuildConfig作成** - GitHubからソースを取得してDockerビルド
5. **ビルド実行** - `oc start-build` でイメージをビルド
6. **Knative Service デプロイ** - ビルドしたイメージでサービスを作成
7. **Ready状態を待機** - 最大5分間待機
8. **サービスURL表示** - デプロイ完了後にアクセス情報を表示

## デプロイされたサービスのテスト

### サービスURLの取得

```bash
# 環境変数を設定 (必要に応じて)
export NAMESPACE=demo-serverless

# Quarkus Native
oc get ksvc quarkus-todo-native -n $NAMESPACE -o jsonpath='{.status.url}'

# Quarkus JVM
oc get ksvc quarkus-todo-jvm -n $NAMESPACE -o jsonpath='{.status.url}'

# Spring Boot JVM
oc get ksvc spring-todo-jvm -n $NAMESPACE -o jsonpath='{.status.url}'
```

### ヘルスチェック

```bash
# サービスURLを変数に設定
export SERVICE_URL=$(oc get ksvc quarkus-todo-native -n $NAMESPACE -o jsonpath='{.status.url}')

# Quarkus (Native/JVM)
curl $SERVICE_URL/q/health/ready
curl $SERVICE_URL/q/health/live

# Spring Boot
curl $SERVICE_URL/actuator/health/readiness
curl $SERVICE_URL/actuator/health/liveness
```

### API テスト

すべてのサービスで同じAPIエンドポイントが利用可能です。

```bash
# Todoリストの取得
curl $SERVICE_URL/api/todos

# Todoの作成
curl -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Test from OpenShift Serverless",
    "description": "Testing Quarkus/Spring on Knative"
  }'

# Todoの取得 (ID=1)
curl $SERVICE_URL/api/todos/1

# Todoの更新
curl -X PUT $SERVICE_URL/api/todos/1 \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Updated Title",
    "description": "Updated Description",
    "completed": true
  }'

# Todoの削除
curl -X DELETE $SERVICE_URL/api/todos/1
```

### 統計情報の取得 (Quarkus)

```bash
# Metrics
curl $SERVICE_URL/q/metrics

# OpenAPI Spec
curl $SERVICE_URL/q/openapi
```

### 統計情報の取得 (Spring Boot)

```bash
# Actuator エンドポイント
curl $SERVICE_URL/actuator

# Metrics
curl $SERVICE_URL/actuator/metrics
```

## サービスの監視

### Podの状態確認

```bash
# すべてのPodを表示
oc get pods -n $NAMESPACE

# 特定のアプリのPodを表示
oc get pods -n $NAMESPACE -l app=quarkus-todo-native

# Auto-scalingの動作確認 (アクセスがないとPodが0になる)
watch oc get pods -n $NAMESPACE
```

### ログの確認

```bash
# リアルタイムログ (Quarkus Native)
oc logs -f -l app=quarkus-todo-native -n $NAMESPACE

# リアルタイムログ (Quarkus JVM)
oc logs -f -l app=quarkus-todo-jvm -n $NAMESPACE

# リアルタイムログ (Spring Boot)
oc logs -f -l app=spring-todo-jvm -n $NAMESPACE
```

### Knative Serviceの状態確認

```bash
# すべてのKnative Serviceを表示
oc get ksvc -n $NAMESPACE

# 詳細情報
oc describe ksvc quarkus-todo-native -n $NAMESPACE

# YAML形式で表示
oc get ksvc quarkus-todo-native -n $NAMESPACE -o yaml
```

### イベントの確認

```bash
# 最近のイベントを時系列で表示
oc get events -n $NAMESPACE --sort-by='.lastTimestamp'

# エラーのみ表示
oc get events -n $NAMESPACE --field-selector type=Warning
```

## Scale-to-Zero の動作確認

Knative Serverlessの特徴的な機能であるScale-to-Zeroの動作を確認できます。

```bash
# 1. サービスにアクセスしてPodを起動
curl $SERVICE_URL/api/todos

# 2. Podが起動していることを確認
oc get pods -n $NAMESPACE -l app=quarkus-todo-native

# 3. 待機 (Quarkus Native: 30秒, Quarkus JVM/Spring Boot: 2分)
# Quarkus Nativeの場合
sleep 40

# 4. Podが0にスケールダウンしたことを確認
oc get pods -n $NAMESPACE -l app=quarkus-todo-native

# 5. 再度アクセスして起動時間を確認
time curl $SERVICE_URL/api/todos
```

**期待される起動時間:**
- Quarkus Native: 数百ミリ秒〜1秒
- Quarkus JVM: 数秒
- Spring Boot JVM: 10秒以上

## トラブルシューティング

### ビルドが失敗する場合

```bash
# ビルドログの確認
oc logs -f bc/quarkus-todo-native -n $NAMESPACE

# ビルドPodの確認
oc get pods -n $NAMESPACE | grep build

# ビルドの再実行
oc start-build quarkus-todo-native -n $NAMESPACE --follow
```

### サービスがReadyにならない場合

```bash
# サービスの状態確認
oc get ksvc quarkus-todo-native -n $NAMESPACE

# 詳細情報
oc describe ksvc quarkus-todo-native -n $NAMESPACE

# Podのログ確認
oc logs -l app=quarkus-todo-native -n $NAMESPACE

# イベント確認
oc get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20
```

### イメージがPullできない場合

```bash
# ImageStreamの確認
oc get is -n $NAMESPACE

# ImageStreamの詳細
oc describe is quarkus-todo-native -n $NAMESPACE

# イメージタグの確認
oc get istag -n $NAMESPACE
```

### メモリ不足エラーの場合

Knative Serviceの `knative-service.yaml` を編集してリソースを増やします。

```yaml
resources:
  requests:
    memory: "512Mi"  # 増やす
    cpu: "200m"
  limits:
    memory: "1Gi"    # 増やす
    cpu: "1000m"
```

再デプロイ:

```bash
# deploy.sh を再実行
./deploy.sh
```

## クリーンアップ

### 個別のサービス削除

```bash
# Quarkus Native
oc delete ksvc quarkus-todo-native -n demo-serverless
oc delete bc quarkus-todo-native -n demo-serverless
oc delete is quarkus-todo-native -n demo-serverless

# Quarkus JVM
oc delete ksvc quarkus-todo-jvm -n demo-serverless
oc delete bc quarkus-todo-jvm -n demo-serverless
oc delete is quarkus-todo-jvm -n demo-serverless

# Spring Boot JVM
oc delete ksvc spring-todo-jvm -n demo-serverless
oc delete bc spring-todo-jvm -n demo-serverless
oc delete is spring-todo-jvm -n demo-serverless
```

### ネームスペースごと削除

```bash
# すべてのリソースを削除
oc delete namespace demo-serverless
```

## 3つのデプロイ方式の比較

| 項目 | Quarkus Native | Quarkus JVM | Spring Boot JVM |
|------|----------------|-------------|-----------------|
| **起動時間** | 数百ms | 数秒 | 10秒以上 |
| **メモリ使用量** | 64-128 Mi | 256-512 Mi | 384-768 Mi |
| **CPU使用量** | 極小 | 小 | 中 |
| **ビルド時間** | 10-15分 | 3-5分 | 3-5分 |
| **Scale-to-zero** | 30秒 | 2分 | 2分 |
| **コールドスタート** | 最速 | 高速 | 標準 |
| **コスト効率** | 最高 | 高 | 標準 |
| **用途** | 高頻度スケーリング | バランス型 | 標準アプリ |

### 推奨される用途

**Quarkus Native を選ぶべき場合:**
- コールドスタートを最小限にしたい
- メモリ使用量を最小化したい
- 頻繁にスケールイン/アウトする
- コストを最小化したい

**Quarkus JVM を選ぶべき場合:**
- 起動時間とメモリのバランスが重要
- ビルド時間を短縮したい
- 開発とデプロイのサイクルを高速化したい

**Spring Boot JVM を選ぶべき場合:**
- 既存のSpring Boot資産を活用したい
- Spring Bootのエコシステムが必要
- 標準的なJavaアプリケーションとして運用したい

## データベース構成

すべてのデプロイメントは、サーバレス環境に適した **H2 in-memory データベース** を使用します。

### データベース設定

**Quarkus (Native/JVM):**
```properties
QUARKUS_DATASOURCE_JDBC_URL=jdbc:h2:mem:tododb;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH
```

**Spring Boot:**
```properties
SPRING_DATASOURCE_URL=jdbc:h2:mem:tododb;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH
SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop
```

### 注意事項

- データはメモリ内に保存され、Podが再起動すると失われます
- Scale-to-zeroで0になると、データも失われます
- 本番環境では、外部データベース (PostgreSQL, MySQL等) を使用することを推奨

### 永続化が必要な場合

本番環境で永続化が必要な場合は、以下の手順で外部データベースを構成します。

1. OpenShift上にPostgreSQLをデプロイ
2. Knative Serviceの環境変数を更新
3. データベース接続情報をSecretとして管理

詳細な手順は、OpenShiftおよびデータベースのドキュメントを参照してください。

## 参考情報

### OpenShift Serverless
- [Red Hat OpenShift Serverless](https://docs.openshift.com/container-platform/latest/serverless/about-serverless.html)
- [Knative Serving Documentation](https://knative.dev/docs/serving/)

### Quarkus
- [Quarkus Official Site](https://quarkus.io/)
- [Quarkus on OpenShift](https://quarkus.io/guides/deploying-to-openshift)
- [Quarkus Native Image](https://quarkus.io/guides/building-native-image)

### Spring Boot
- [Spring Boot Official Site](https://spring.io/projects/spring-boot)
- [Spring Boot on OpenShift](https://spring.io/guides/gs/spring-boot-kubernetes/)

## ライセンス

このプロジェクトのライセンスについては、リポジトリのルートディレクトリを参照してください。
