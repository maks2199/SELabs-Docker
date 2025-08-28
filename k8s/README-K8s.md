# Kubernetes/kind запуск (минимальный эквивалент)

```bash
# 1) Создать кластер
kind create cluster --config k8s/kind-config.yaml

# 2) Собрать и загрузить образ
docker build -t docker-lab/orders-api:optimized -f Dockerfile .
kind load docker-image docker-lab/orders-api:optimized

# 3) Применить манифесты
kubectl apply -f k8s/orders-api.yaml

# 4) Проверки
curl -s http://localhost:30081/health | jq .
curl -s http://localhost:30081/orders | jq .
```
> Примечание: в примере используется emptyDir. Для постоянного хранения данных подключайте PVC/StorageClass.
