# Spring Boot JVM on OpenShift Serverless - テストガイド

Spring Boot JVMアプリケーションがOpenShift Serverlessに正しくデプロイされていることを確認するためのテストガイドです。

## サービスURLの確認

```bash
# サービスURLを取得
oc get ksvc spring-todo-jvm -n demo-serverless -o jsonpath='{.status.url}'

# 環境変数に設定（以降のテストで使用）
export SERVICE_URL=$(oc get ksvc spring-todo-jvm -n demo-serverless -o jsonpath='{.status.url}')

# URLを表示
echo $SERVICE_URL
```

**例:**
```
https://spring-todo-jvm-demo-serverless.apps.cluster-xxxxx.opentlc.com
```

## 基本的なテストコマンド

### 1. ヘルスチェック

```bash
# Readiness Check（起動完了確認）
curl $SERVICE_URL/actuator/health/readiness

# 期待される出力:
# {"status":"UP"}

# Liveness Check（アプリケーション正常性確認）
curl $SERVICE_URL/actuator/health/liveness

# 期待される出力:
# {"status":"UP"}
```

### 2. Actuator エンドポイント一覧

```bash
# 利用可能なActuatorエンドポイントを確認
curl $SERVICE_URL/actuator

# JSONを見やすく表示（jqが必要）
curl -s $SERVICE_URL/actuator | jq .
```

### 3. アプリケーション情報

```bash
# アプリケーション情報
curl $SERVICE_URL/actuator/info

# 環境変数
curl $SERVICE_URL/actuator/env

# メトリクス一覧
curl $SERVICE_URL/actuator/metrics

# JVMメモリ使用量
curl $SERVICE_URL/actuator/metrics/jvm.memory.used
```

## API エンドポイントのテスト

### 1. Todoリストの取得（GET /api/todos）

```bash
# すべてのTodoを取得（初期状態は空）
curl $SERVICE_URL/api/todos

# 期待される出力:
# []

# JSONを見やすく表示
curl -s $SERVICE_URL/api/todos | jq .
```

### 2. Todoの作成（POST /api/todos）

```bash
# 新しいTodoを作成
curl -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Test from OpenShift",
    "description": "Spring Boot JVM on Serverless"
  }'

# 期待される出力:
# {"id":1,"title":"Test from OpenShift","description":"Spring Boot JVM on Serverless","completed":false}

# 見やすく表示
curl -s -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Second Todo","description":"Testing Spring Boot"}' | jq .
```

### 3. 特定のTodoの取得（GET /api/todos/{id}）

```bash
# ID=1のTodoを取得
curl $SERVICE_URL/api/todos/1

# 期待される出力:
# {"id":1,"title":"Test from OpenShift","description":"Spring Boot JVM on Serverless","completed":false}

# 見やすく表示
curl -s $SERVICE_URL/api/todos/1 | jq .
```

### 4. Todoの更新（PUT /api/todos/{id}）

```bash
# ID=1のTodoを更新
curl -X PUT $SERVICE_URL/api/todos/1 \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Updated Title",
    "description": "Updated Description",
    "completed": true
  }'

# 期待される出力:
# {"id":1,"title":"Updated Title","description":"Updated Description","completed":true}

# 見やすく表示
curl -s -X PUT $SERVICE_URL/api/todos/1 \
  -H 'Content-Type: application/json' \
  -d '{"title":"Done","description":"Completed task","completed":true}' | jq .
```

### 5. Todoの削除（DELETE /api/todos/{id}）

```bash
# ID=1のTodoを削除
curl -X DELETE $SERVICE_URL/api/todos/1

# 期待される出力: (空のレスポンス)

# 削除後、リストを確認
curl -s $SERVICE_URL/api/todos | jq .

# 期待される出力:
# []
```

## バリデーションテスト

### 1. 必須項目のテスト

```bash
# titleなしでTodoを作成（エラーになるはず）
curl -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "No title"
  }'

# 期待される出力: エラーメッセージ
```

### 2. 存在しないIDのテスト

```bash
# 存在しないIDを取得
curl -s $SERVICE_URL/api/todos/999

# 期待される出力: 404 Not Found
```

## パフォーマンステスト

### 1. コールドスタート時間の測定

```bash
# まずPodが存在しないことを確認（scale-to-zeroで0になるまで待つ）
oc get pods -n demo-serverless -l app=spring-todo-jvm

# Podが0の状態で、時間を測定してリクエスト
time curl $SERVICE_URL/api/todos

# Spring Boot JVMの期待値: 10-20秒程度
```

### 2. ウォームアップ後のレスポンス時間

```bash
# 連続してリクエストを送信
for i in {1..10}; do
  time curl -s $SERVICE_URL/api/todos > /dev/null
  sleep 0.5
done
```

### 3. メモリ使用量の確認

```bash
# Podのメモリ使用量を確認
oc adm top pod -n demo-serverless -l app=spring-todo-jvm

# 期待値: 300-600Mi程度
```

## Scale-to-Zero の動作確認

```bash
# 1. サービスにアクセスしてPodを起動
curl $SERVICE_URL/api/todos

# 2. Podが起動していることを確認
oc get pods -n demo-serverless -l app=spring-todo-jvm

# 3. 2分間待機（scale-to-zero-pod-retention-period: "2m"）
echo "Waiting 2 minutes for scale-to-zero..."
sleep 130

# 4. Podが0にスケールダウンしたことを確認
oc get pods -n demo-serverless -l app=spring-todo-jvm

# 期待される出力: No resources found (Podが存在しない)

# 5. 再度アクセスして起動時間を測定
echo "Testing cold start..."
time curl $SERVICE_URL/api/todos
```

## 統合テストスクリプト

包括的なテストを実行するには、同じディレクトリの `test.sh` スクリプトを使用してください。

```bash
# テストスクリプトを実行
./test.sh

# または、カスタムURLで実行
./test.sh https://spring-todo-jvm-demo-serverless.apps.cluster-xxxxx.opentlc.com
```

## トラブルシューティング

### 接続エラーが発生する場合

```bash
# サービスの状態を確認
oc get ksvc spring-todo-jvm -n demo-serverless

# Podの状態を確認
oc get pods -n demo-serverless -l app=spring-todo-jvm

# ログを確認
oc logs -n demo-serverless -l app=spring-todo-jvm --tail=100
```

### タイムアウトが発生する場合

```bash
# イベントを確認
oc get events -n demo-serverless --sort-by='.lastTimestamp' | tail -20

# サービスの詳細を確認
oc describe ksvc spring-todo-jvm -n demo-serverless
```

### 404エラーが発生する場合

```bash
# ルートパスにアクセスして確認
curl $SERVICE_URL/

# Actuatorエンドポイントで確認
curl $SERVICE_URL/actuator/health
```

## Spring BootとQuarkusの比較テスト

同じネームスペースにQuarkus JVMもデプロイされている場合、比較テストが可能です。

```bash
# 環境変数を設定
export SPRING_URL=$(oc get ksvc spring-todo-jvm -n demo-serverless -o jsonpath='{.status.url}')
export QUARKUS_URL=$(oc get ksvc quarkus-todo-jvm -n demo-serverless -o jsonpath='{.status.url}')

# 起動時間の比較
echo "=== Spring Boot JVM ==="
time curl -s $SPRING_URL/api/todos > /dev/null

echo ""
echo "=== Quarkus JVM ==="
time curl -s $QUARKUS_URL/api/todos > /dev/null

# メモリ使用量の比較
echo ""
echo "=== Memory Usage ==="
echo "Spring Boot JVM:"
oc adm top pod -n demo-serverless -l app=spring-todo-jvm
echo ""
echo "Quarkus JVM:"
oc adm top pod -n demo-serverless -l app=quarkus-todo-jvm
```

## 参考情報

- Spring Boot Actuator: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html
- OpenShift Serverless: https://docs.openshift.com/container-platform/latest/serverless/about-serverless.html
- Knative Serving: https://knative.dev/docs/serving/
