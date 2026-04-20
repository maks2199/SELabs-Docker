# Stage 1 — Сборка: разбор сценария

## Симптом

- `docker run <image>` завершается за ~1 секунду.
- `docker ps` — пусто; `docker ps -a` показывает контейнер в статусе `Exited (3)`.
- `docker logs <container>` — `ModuleNotFoundError: No module named 'app'`.

## Что сломано

В Dockerfile перед `CMD` добавлена лишняя строка `WORKDIR /srv`. Файлы приложения лежат в `/app` (COPY отработал корректно), но стартовая директория — пустой `/srv`.

Diff против рабочего Dockerfile:

```diff
  FROM python:3.11
  WORKDIR /app
  COPY app/requirements.txt .
  RUN pip install -r requirements.txt
  COPY app /app
+ WORKDIR /srv
  CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]
```

## Корневая причина

`WORKDIR` в Dockerfile задаёт не только «куда копировать» для последующих `COPY` — это ещё и `cwd` для `CMD`. Когда `WORKDIR /srv` появляется перед `CMD`, gunicorn стартует из пустой `/srv`, пытается импортировать модуль `app` из текущей директории, не находит, падает с exit code 3.

## Проявления по чеклисту диагностики

1. **ps -a** — `Exited (3)` через ~1 сек после старта.
2. **logs** — `ModuleNotFoundError: No module named 'app'`.
3. **inspect** — `Config.WorkingDir = "/srv"` (вместо ожидаемого `/app`).
4. **exec** — напрямую недоступно (контейнер уже остановлен). Альтернатива:
   ```
   docker run --rm -it --entrypoint sh <image>
   pwd    # → /srv
   ls     # → пусто
   ls /app  # → код приложения тут
   ```
5. **Сравнение** — код в `/app`, cwd в `/srv`. Расхождение найдено.

## Лечение

Убрать строку `WORKDIR /srv` (или заменить на `WORKDIR /app`, если нужно явно обозначить рабочую директорию). Пересобрать образ.

## Что выносит студент

`WORKDIR` — не косметика. Это одновременно «куда идут COPY-файлы» и «откуда запускается CMD». Быстрая диагностика в inspect: `Config.WorkingDir`.
