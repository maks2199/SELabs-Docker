# Stage 2 — Управление: разбор сценария

## Симптом

- После `docker compose up -d` контейнер `backend-orders-api` через несколько секунд переходит в `Restarting (1)`.
- В `docker ps` цикл повторяется каждые ~10 секунд.
- Эндпоинт `http://localhost:8081` не отвечает (контейнер не успевает подняться).

## Что сломано

В `docker-compose.broken.yml` переменной `DB_PATH` задан путь в несуществующую директорию `/forbidden/`, а `command` пробует открыть файл базы данных до запуска gunicorn:

```yaml
environment:
  DB_PATH: /forbidden/orders.db
command: >
  sh -c "python -c 'import os, sqlite3; sqlite3.connect(os.environ[\"DB_PATH\"])' &&
         gunicorn -b 0.0.0.0:8080 app:app"
restart: unless-stopped
```

`restart: unless-stopped` превращает разовый краш в бесконечный цикл — отсюда `Restarting (1)`.

## Корневая причина

Приложение читает `DB_PATH` из окружения и пытается открыть SQLite-базу по этому пути. Директория `/forbidden/` в образе отсутствует, `sqlite3.connect` кидает `OperationalError: unable to open database file`. Gunicorn-воркер падает, контейнер выходит, compose перезапускает — цикл.

## Проявления по чеклисту диагностики

1. **ps -a** — `Restarting (1)` или `Up Less than a second` (поймать в момент рестарта).
2. **logs** — `sqlite3.OperationalError: unable to open database file` + traceback.
3. **inspect** — секция `Config.Env`: `DB_PATH=/forbidden/orders.db`. Секция `HostConfig.RestartPolicy`: `unless-stopped`.
4. **exec** — в момент, когда контейнер запущен:
   ```
   docker exec backend-orders-api printenv | grep DB_PATH
   # → DB_PATH=/forbidden/orders.db
   docker exec backend-orders-api ls /forbidden
   # → ls: cannot access '/forbidden': No such file or directory
   ```
   Если `exec` не успевает — отключить рестарт (`docker update --restart=no backend-orders-api`) или запустить контейнер из того же образа вручную.
5. **Сравнение** — `DB_PATH` указывает в несуществующую директорию. Либо директория должна быть создана (маунт/mkdir), либо путь должен быть другим.

## Лечение

Убрать `DB_PATH` из `environment` (приложение использует дефолт `./data/orders.db` — рабочий) или прописать корректный путь внутри существующей директории (`/app/data/orders.db`).

## Что выносит студент

Docker не валидирует значения env-переменных — отдаёт их приложению as-is. Мусорная строка в env → рестарт-луп. Диагностика: `logs` показывает *что* сломалось в приложении, `inspect`/`exec printenv` — *почему* приложение оказалось с таким значением.
