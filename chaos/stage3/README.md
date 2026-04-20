# Stage 3 — Монтирование: разбор сценария

## Симптом

- `docker compose up -d` проходит успешно. Контейнер `mount-example` стартует, приложение открывается в браузере.
- Студент создаёт файлы через интерфейс — они появляются в UI.
- После `docker compose down && docker compose up -d` все файлы пропадают — UI показывает пустой список.

## Что сломано

В `docker-compose.broken.yml` volume указан в несуществующий путь внутри контейнера:

```yaml
volumes:
  - ./data:/wrong/path      # ← должно быть /app/data
```

Приложение (Node.js file-browser) пишет файлы в `/app/data` (см. `server.js` в исходниках mount-example: `dataDir = path.join(__dirname, "data")`). Mount примонтирован мимо — в `/wrong/path`, который приложение даже не открывает.

## Корневая причина

Mount сам по себе работает штатно: `./data` на хосте и `/wrong/path` в контейнере синхронизированы. Проблема в том, что приложение пишет по **другому** пути — `/app/data` — который при этом внутри контейнера является обычной эфемерной директорией. При `docker compose down` слой контейнера удаляется, файлы теряются.

## Проявления по чеклисту диагностики

1. **ps -a** — `Up`, всё выглядит нормально.
2. **logs** — без ошибок, приложение работает.
3. **inspect** — `Mounts[].Destination = "/wrong/path"` (не `/app/data`).
4. **exec** — ключевой шаг:
   ```
   docker exec mount-example ls /app/data
   # → список файлов, созданных через UI
   docker exec mount-example ls /wrong/path
   # → пусто (или только dotfiles)
   ```
5. **Сравнение** — приложение пишет в `/app/data`, mount указывает на `/wrong/path`. Не совпадает.

## Лечение

Исправить путь назначения volume:

```yaml
volumes:
  - ./data:/app/data
```

## Что выносит студент

Bind mount — это «замена» директории внутри контейнера, а не «волшебный клей». Если путь не совпадает с тем, куда реально пишет приложение, mount технически работает, но бесполезен. Диагностика: `docker inspect` → `Mounts[].Destination` + `docker exec <container> ls <expected-path>`.
