# Stage 2 — Управление: разбор сценария

## Симптом

- `docker compose up -d` проходит успешно. Контейнер `backend-orders-api` в статусе `Up`.
- `curl http://localhost:8081/` (корневой эндпоинт) отвечает нормально.
- `curl http://localhost:8081/orders` — возвращает HTTP 500 или зависает.
- `docker logs backend-orders-api` — стек `sqlite3.OperationalError: unable to open database file`.

## Что сломано

В `docker-compose.broken.yml` переменной `DB_PATH` задан путь в несуществующую директорию `/forbidden/`:

```yaml
environment:
  DB_PATH: /forbidden/orders.db
```

## Корневая причина

Приложение читает `DB_PATH` из окружения при импорте модуля, но SQLite-коннект делает лениво — только при первом запросе к эндпоинту, который обращается к базе (`/orders`, `/health`). До первого запроса контейнер выглядит живым: порт проброшен, gunicorn слушает, статус `Up`.

На первом запросе `sqlite3.connect("/forbidden/orders.db")` пытается открыть файл в несуществующей директории → `OperationalError: unable to open database file`. Flask возвращает 500, приложение продолжает работать (воркер не падает — просто ручка отдаёт ошибку).

## Проявления по чеклисту диагностики

1. **ps -a** — `Up`, всё выглядит нормально. Контейнер работает.
2. **logs** — пусто до первого запроса. После обращения к `/orders` — `sqlite3.OperationalError: unable to open database file` + traceback.
3. **inspect** — `Config.Env`: `DB_PATH=/forbidden/orders.db`. Ключевая улика.
4. **exec** — контейнер живой, можно спокойно заходить:
   ```
   docker exec backend-orders-api printenv | grep DB_PATH
   # → DB_PATH=/forbidden/orders.db
   docker exec backend-orders-api ls /forbidden
   # → ls: cannot access '/forbidden': No such file or directory
   ```
5. **Сравнение** — `DB_PATH` указывает в несуществующую директорию. Либо директория должна быть создана (маунт/mkdir), либо путь должен быть другим.

## Лечение

Убрать `DB_PATH` из `environment` (приложение использует дефолт `./data/orders.db` — рабочий) или прописать корректный путь внутри существующей директории (`/app/data/orders.db`).

## Что выносит студент

Docker не валидирует значения env-переменных — отдаёт их приложению as-is. Мусорная строка в env переживает `up -d`: порт открыт, статус `Up`, но первый запрос падает. Диагностика: `logs` показывает *что* сломалось в приложении, `inspect`/`exec printenv` — *почему* приложение оказалось с таким значением. Урок: «контейнер запустился» ≠ «приложение работает».
