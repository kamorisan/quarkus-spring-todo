# 環境変数に設定
export SERVICE_URL=https://quarkus-todo-native-demo-serverless.apps.cluster-5rxv7.5rxv7.sandbox2408.opentlc.com

# 1. ヘルスチェック（Ready）
curl $SERVICE_URL/q/health/ready

# 2. ヘルスチェック（Live）
curl $SERVICE_URL/q/health/live

# 3. Todoリスト取得（最初は空）
curl $SERVICE_URL/api/todos

# 4. Todoを作成
curl -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Test from Serverless","description":"Quarkus Native on OpenShift"}'

# 5. 再度Todoリスト取得（作成したTodoが表示される）
curl $SERVICE_URL/api/todos

# 6. 特定のTodo取得（ID=1）
curl $SERVICE_URL/api/todos/1

# 7. Todoを更新
curl -X PUT $SERVICE_URL/api/todos/1 \
  -H 'Content-Type: application/json' \
  -d '{"title":"Updated Title","description":"Updated Description","completed":true}'

# 8. 更新後のTodoを確認
curl $SERVICE_URL/api/todos/1

# 9. Todoを削除
curl -X DELETE $SERVICE_URL/api/todos/1

# 10. 削除後のリスト確認（空になる）
curl $SERVICE_URL/api/todos

# 11. メトリクス確認（Native Image特有のメトリクス）
curl $SERVICE_URL/q/metrics

# 12. OpenAPI仕様を取得
curl $SERVICE_URL/q/openapi
