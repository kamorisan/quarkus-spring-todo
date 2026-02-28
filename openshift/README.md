# OpenShift Deployment Guide

QuarkusとSpring Bootのアプリケーションを、OpenShiftにデプロイするためのリソースとスクリプトです。

**2つのデプロイメントモードをサポート:**
- **Serverless** - Knative Serving (scale-to-zero機能付き)
- **Standard** - 通常のDeployment

## 概要

このディレクトリには、3つのアプリケーションを2つの異なるモードでデプロイするためのリソースが含まれています。

### アプリケーション

1. **Quarkus Native Image** - 超高速起動と最小メモリフットプリント
2. **Quarkus JVM** - 高速起動とバランスの取れたパフォーマンス
3. **Spring Boot JVM** - 標準的なSpring Bootアプリケーション

### デプロイメントモード

| モード | 特徴 | 用途 |
|--------|------|------|
| **Serverless** | Scale-to-zero、オートスケーリング | 間欠的なトラフィック、開発/テスト環境 |
| **Standard** | 常時稼働、手動スケーリング | 継続的なトラフィック、本番環境 |

すべてのデプロイメントは、GitHubリポジトリ (`https://github.com/kamorisan/quarkus-spring-todo.git`) からソースコードを取得し、OpenShift上でビルドしてデプロイします。

## 前提条件

### 必須要件

1. **OpenShiftクラスターへのアクセス**
   - OpenShift 4.x クラスター
   - Serverlessモード使用時: OpenShift Serverless (Knative Serving) がインストール済み

2. **CLIツール**
   - `oc` コマンド (OpenShift CLI)
   - OpenShiftクラスターにログイン済み

3. **権限**
   - プロジェクト/ネームスペースの作成権限
   - BuildConfig、ImageStream、Deployment/Knative Serviceの作成権限

### 確認方法

```bash
# OpenShiftにログインしているか確認
oc whoami
oc whoami --show-server

# Serverlessモード使用時: Knative Servingが利用可能か確認
oc api-resources | grep knative
```

## ディレクトリ構成

```
openshift/
├── README.md                     # このファイル
├── quarkus-native/               # Quarkus Native Image
│   ├── Dockerfile                # マルチステージビルド (GraalVM)
│   ├── knative-service.yaml      # Serverlessモード用
│   ├── deployment.yaml           # Standardモード用
│   ├── service.yaml              # Standardモード用
│   ├── route.yaml                # Standardモード用
│   └── deploy.sh                 # デプロイスクリプト
├── quarkus-jvm/                  # Quarkus JVM
│   ├── Dockerfile                # マルチステージビルド (OpenJDK 21)
│   ├── knative-service.yaml      # Serverlessモード用
│   ├── deployment.yaml           # Standardモード用
│   ├── service.yaml              # Standardモード用
│   ├── route.yaml                # Standardモード用
│   └── deploy.sh                 # デプロイスクリプト
└── spring-jvm/                   # Spring Boot JVM
    ├── Dockerfile                # マルチステージビルド (OpenJDK 21)
    ├── knative-service.yaml      # Serverlessモード用
    ├── deployment.yaml           # Standardモード用
    ├── service.yaml              # Standardモード用
    ├── route.yaml                # Standardモード用
    ├── deploy.sh                 # デプロイスクリプト
    ├── test.sh                   # APIテストスクリプト
    └── TEST.md                   # テストガイド
```

## クイックスタート

### Serverlessモードでデプロイ

```bash
# Quarkus Native Image
cd openshift/quarkus-native
./deploy.sh serverless

# Quarkus JVM
cd openshift/quarkus-jvm
./deploy.sh serverless

# Spring Boot JVM
cd openshift/spring-jvm
./deploy.sh serverless
```

### Standardモードでデプロイ

```bash
# Quarkus Native Image
cd openshift/quarkus-native
./deploy.sh standard

# Quarkus JVM
cd openshift/quarkus-jvm
./deploy.sh standard

# Spring Boot JVM
cd openshift/spring-jvm
./deploy.sh standard
```

## デプロイメント詳細

### 共通の環境変数

すべてのデプロイスクリプトで以下の環境変数をサポートしています。

```bash
# ネームスペース名
# Serverlessモード: デフォルト demo-serverless
# Standardモード: デフォルト demo-apps
export OPENSHIFT_NAMESPACE=my-namespace

# Gitリポジトリ (デフォルト: https://github.com/kamorisan/quarkus-spring-todo.git)
export GIT_REPO=https://github.com/your-repo.git

# Gitブランチ (デフォルト: main)
export GIT_BRANCH=develop
```

### Serverlessモード

**特徴:**
- Knative Serviceとしてデプロイ
- 自動スケーリング (0〜10 pods)
- アイドル時にscale-to-zero

**ネームスペース:** `demo-serverless` (デフォルト)

**デプロイ手順:**

```bash
cd openshift/quarkus-native  # または quarkus-jvm, spring-jvm
./deploy.sh serverless
```

**リソース設定:**

| アプリケーション | Memory (Request/Limit) | CPU (Request/Limit) | Scale-to-zero |
|-----------------|------------------------|---------------------|---------------|
| Quarkus Native  | 64Mi / 128Mi           | 50m / 200m          | 30秒          |
| Quarkus JVM     | 256Mi / 512Mi          | 100m / 500m         | 2分           |
| Spring Boot JVM | 384Mi / 768Mi          | 100m / 500m         | 2分           |

**サービスURL取得:**

```bash
# 環境変数を設定
export NAMESPACE=demo-serverless

# URLを取得
oc get ksvc quarkus-todo-native -n $NAMESPACE -o jsonpath='{.status.url}'
oc get ksvc quarkus-todo-jvm -n $NAMESPACE -o jsonpath='{.status.url}'
oc get ksvc spring-todo-jvm -n $NAMESPACE -o jsonpath='{.status.url}'
```

### Standardモード

**特徴:**
- 通常のDeploymentとしてデプロイ
- 常時稼働 (replica=1)
- 手動でスケーリング可能

**ネームスペース:** `demo-apps` (デフォルト)

**デプロイ手順:**

```bash
cd openshift/quarkus-native  # または quarkus-jvm, spring-jvm
./deploy.sh standard
```

**リソース設定:**

| アプリケーション | Memory (Request/Limit) | CPU (Request/Limit) |
|-----------------|------------------------|---------------------|
| Quarkus Native  | 64Mi / 128Mi           | 50m / 200m          |
| Quarkus JVM     | 256Mi / 512Mi          | 100m / 500m         |
| Spring Boot JVM | 384Mi / 768Mi          | 100m / 500m         |

**RouteURL取得:**

```bash
# 環境変数を設定
export NAMESPACE=demo-apps

# URLを取得
oc get route quarkus-todo-native -n $NAMESPACE -o jsonpath='{.spec.host}'
oc get route quarkus-todo-jvm -n $NAMESPACE -o jsonpath='{.spec.host}'
oc get route spring-todo-jvm -n $NAMESPACE -o jsonpath='{.spec.host}'
```

**スケーリング:**

```bash
# レプリカ数を3に増やす
oc scale deployment/quarkus-todo-native -n $NAMESPACE --replicas=3

# 確認
oc get pods -n $NAMESPACE -l app=quarkus-todo-native
```

## テスト方法

### ヘルスチェック

**Quarkus (Native/JVM):**

```bash
# Serverlessモード
SERVICE_URL=$(oc get ksvc quarkus-todo-native -n demo-serverless -o jsonpath='{.status.url}')
curl $SERVICE_URL/q/health/ready

# Standardモード
ROUTE_URL=$(oc get route quarkus-todo-native -n demo-apps -o jsonpath='{.spec.host}')
curl https://$ROUTE_URL/q/health/ready
```

**Spring Boot:**

```bash
# Serverlessモード
SERVICE_URL=$(oc get ksvc spring-todo-jvm -n demo-serverless -o jsonpath='{.status.url}')
curl $SERVICE_URL/actuator/health/readiness

# Standardモード
ROUTE_URL=$(oc get route spring-todo-jvm -n demo-apps -o jsonpath='{.spec.host}')
curl https://$ROUTE_URL/actuator/health/readiness
```

### API テスト

```bash
# Todoリストの取得
curl $SERVICE_URL/api/todos

# Todoの作成
curl -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Test","description":"Testing on OpenShift"}'

# 詳細なテスト
cd openshift/spring-jvm
./test.sh $SERVICE_URL
```

詳細は [openshift/spring-jvm/TEST.md](spring-jvm/TEST.md) を参照してください。

## モード別の比較

### Serverless vs Standard

| 項目 | Serverless | Standard |
|------|-----------|----------|
| **起動方式** | オンデマンド (scale-from-zero) | 常時稼働 |
| **スケーリング** | 自動 (0-10) | 手動 |
| **コスト** | 使用時のみ課金 | 常時課金 |
| **コールドスタート** | あり | なし |
| **適用シーン** | 開発/テスト、間欠的なトラフィック | 本番環境、継続的なトラフィック |
| **必須Operator** | OpenShift Serverless | なし |

### アプリケーション別の性能比較

| 項目 | Quarkus Native | Quarkus JVM | Spring Boot JVM |
|------|----------------|-------------|-----------------|
| **起動時間** | 数百ms | 数秒 | 10秒以上 |
| **メモリ使用量** | 50-100Mi | 200-400Mi | 300-600Mi |
| **CPU使用量** | 極小 | 小 | 中 |
| **ビルド時間** | 10-15分 | 3-5分 | 3-5分 |
| **Serverless適性** | 最適 | 良好 | 可能 |
| **コールドスタート** | 最速 | 高速 | 標準 |

## 監視とログ

### Podの確認

```bash
# Serverlessモード
oc get pods -n demo-serverless

# Standardモード
oc get pods -n demo-apps

# 特定のアプリのみ
oc get pods -n demo-serverless -l app=quarkus-todo-native
```

### ログの確認

```bash
# リアルタイムログ
oc logs -f -l app=quarkus-todo-native -n demo-serverless

# 最新100行
oc logs -l app=quarkus-todo-native -n demo-serverless --tail=100
```

### リソース使用状況

```bash
# CPU/メモリ使用量
oc adm top pod -n demo-serverless -l app=quarkus-todo-native
```

### サービス詳細

**Serverlessモード:**

```bash
# Knative Service の詳細
oc get ksvc -n demo-serverless
oc describe ksvc quarkus-todo-native -n demo-serverless
```

**Standardモード:**

```bash
# Deployment の詳細
oc get deployment -n demo-apps
oc describe deployment quarkus-todo-native -n demo-apps

# Service の詳細
oc get service -n demo-apps
oc describe service quarkus-todo-native -n demo-apps

# Route の詳細
oc get route -n demo-apps
oc describe route quarkus-todo-native -n demo-apps
```

## Scale-to-Zero の動作確認 (Serverlessモードのみ)

```bash
# 1. サービスにアクセスしてPodを起動
curl $SERVICE_URL/api/todos

# 2. Podが起動していることを確認
oc get pods -n demo-serverless -l app=quarkus-todo-native

# 3. 待機
# Quarkus Native: 30秒
# Quarkus JVM/Spring Boot: 2分
sleep 130

# 4. Podが0にスケールダウンしたことを確認
oc get pods -n demo-serverless -l app=quarkus-todo-native
# 出力: No resources found (正常)

# 5. 再度アクセスして起動時間を確認
time curl $SERVICE_URL/api/todos
```

**期待される起動時間:**
- Quarkus Native: 数百ms〜1秒
- Quarkus JVM: 数秒
- Spring Boot JVM: 10秒以上

## トラブルシューティング

### ビルドが失敗する場合

```bash
# ビルドログの確認
oc logs -f bc/quarkus-todo-native -n demo-serverless

# ビルドの再実行
oc start-build quarkus-todo-native -n demo-serverless --follow
```

### サービスがReadyにならない場合

**Serverlessモード:**

```bash
# サービスの状態確認
oc get ksvc quarkus-todo-native -n demo-serverless
oc describe ksvc quarkus-todo-native -n demo-serverless

# Podのログ確認
oc logs -l app=quarkus-todo-native -n demo-serverless

# イベント確認
oc get events -n demo-serverless --sort-by='.lastTimestamp' | tail -20
```

**Standardモード:**

```bash
# Deploymentの状態確認
oc get deployment quarkus-todo-native -n demo-apps
oc describe deployment quarkus-todo-native -n demo-apps

# Podの状態確認
oc get pods -n demo-apps -l app=quarkus-todo-native
oc describe pod <pod-name> -n demo-apps

# ログ確認
oc logs <pod-name> -n demo-apps
```

### Knative Servingがインストールされていない場合

Serverlessモードを使用するには、OpenShift Serverless Operatorのインストールが必要です。

```bash
# OpenShift Web Console → OperatorHub
# "OpenShift Serverless" を検索してインストール

# または、Standardモードを使用
./deploy.sh standard
```

## クリーンアップ

### Serverlessモード

```bash
# 個別削除
oc delete ksvc quarkus-todo-native -n demo-serverless
oc delete bc quarkus-todo-native -n demo-serverless
oc delete is quarkus-todo-native -n demo-serverless

# ネームスペースごと削除
oc delete namespace demo-serverless
```

### Standardモード

```bash
# 個別削除
oc delete deployment quarkus-todo-native -n demo-apps
oc delete service quarkus-todo-native -n demo-apps
oc delete route quarkus-todo-native -n demo-apps
oc delete bc quarkus-todo-native -n demo-apps
oc delete is quarkus-todo-native -n demo-apps

# ネームスペースごと削除
oc delete namespace demo-apps
```

## データベース構成

すべてのデプロイメントは、**H2 in-memory データベース** を使用します。

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
- Serverlessモードでscale-to-zeroになると、データも失われます
- 本番環境では、外部データベース (PostgreSQL, MySQL等) を使用することを推奨

## 参考情報

### OpenShift
- [Red Hat OpenShift Documentation](https://docs.openshift.com/)
- [OpenShift Serverless](https://docs.openshift.com/container-platform/latest/serverless/about-serverless.html)

### Knative
- [Knative Serving Documentation](https://knative.dev/docs/serving/)

### Quarkus
- [Quarkus Official Site](https://quarkus.io/)
- [Quarkus on OpenShift](https://quarkus.io/guides/deploying-to-openshift)
- [Quarkus Native Image](https://quarkus.io/guides/building-native-image)

### Spring Boot
- [Spring Boot Official Site](https://spring.io/projects/spring-boot)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)

## ライセンス

このプロジェクトのライセンスについては、リポジトリのルートディレクトリを参照してください。
