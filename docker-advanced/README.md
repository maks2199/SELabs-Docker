# Docker Lab

## Быстрый старт

```bash
# Сборка
./scripts/build-naive.sh
./scripts/build-optimized.sh

# Запуск
./scripts/run-naive.sh      # http://localhost:8081/health
./scripts/run-optimized.sh  # http://localhost:8082/health

# Compose вариант
./scripts/compose-quick.sh  # http://localhost:8083/health

# Диагностика
./scripts/inspect-layers.sh
```

Полезные эндпойнты: `/health`, `/orders?status=paid&limit=1`
