# Stage 4 — Сети: разбор сценария

## Симптом

- `docker compose up -d` проходит. Оба контейнера — `backend-orders-api` и `frontend-orders` — в статусе `Up`.
- Фронтенд открывается по `http://<IP>:3001`.
- Любой запрос к бэкенду через UI возвращает ошибку подключения — `getaddrinfo ENOTFOUND backend` или `ECONNREFUSED`.

## Что сломано

У фронтенда в `environment` указан несуществующий хост:

```yaml
environment:
  BACKEND_HOST: backend       # ← в сети нет ни сервиса, ни контейнера с таким именем
  BACKEND_PORT: "8080"
```

Правильные имена в сети `orders-net`:
- `orders-api` — имя сервиса в compose (резолвится в IP бэкенда).
- `backend-orders-api` — `container_name` (тоже резолвится как бонус).

Слово `backend` — ни сервис, ни container_name.

## Корневая причина

Внутри docker-сети DNS резолвит имена сервисов compose (и container_name как бонус). Произвольные строки не резолвятся. Node.js фронтенд получает DNS-ошибку `ENOTFOUND backend` при первом обращении и падает на каждом запросе.

## Проявления по чеклисту диагностики

1. **ps** — оба контейнера `Up`, всё выглядит нормально.
2. **logs** — `docker logs frontend-orders` показывает `Error: getaddrinfo ENOTFOUND backend` при каждом запросе.
3. **inspect** — `Config.Env`: `BACKEND_HOST=backend`. `NetworkSettings.Networks`: `orders-net`.
4. **exec** — ключевой шаг:
   ```
   docker exec frontend-orders ping -c1 orders-api
   # → отвечает: PING orders-api ... 64 bytes from orders-api ...
   docker exec frontend-orders ping -c1 backend-orders-api
   # → отвечает: PING backend-orders-api ...
   docker exec frontend-orders ping -c1 backend
   # → ping: bad address 'backend'
   ```
   Дополнительно: `docker network inspect orders-net` — видим реальных участников сети.
5. **Сравнение** — `BACKEND_HOST` указывает на имя, которого нет в сети. Сверяем с `docker-compose.yml`: имя сервиса — `orders-api`.

## Лечение

Исправить `BACKEND_HOST` на имя сервиса:

```yaml
environment:
  BACKEND_HOST: orders-api
  BACKEND_PORT: "8080"
```

## Что выносит студент

Внутри docker-сети резолвятся **имена сервисов** из compose-файла (и container_name как бонус). Произвольные строки — нет. Когда видишь `ENOTFOUND`, смотри не в код, а в compose: какое имя реально определено?
