# Этап 2. Управление docker-контейнером — теория.

## Docker compose

### Основная структура `docker-compose.yml`

```yaml
version: "3.9"

services:
  backend:
    build:
      context: ./backend
    ports:
      - "5000:5000"
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    depends_on:
      - db
    networks:
      - app-net

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-net

volumes:
  db-data:

networks:
  app-net:
```

- **`services`** — описание контейнеров приложения
  Раздел, где перечисляются все сервисы (контейнеры), которые будут запускаться.

- **`image`** — готовый образ, который нужно скачать и запустить.

- **`build`** — Указывает, что образ нужно собрать из Dockerfile.

- **`context`** — директория, в которой лежит Dockerfile.

- **`ports`** — Проброс портов: `хост:контейнер`.

- **`env_file`** — Файл с переменными окружения, которые будут загружены в контейнер.

- **`environment`** — Переменные окружения, передаваемые в контейнер.
  Используются для конфигурации базы PostgreSQL.

- **`volumes`** — Монтирование директорий (persist data или доступ к локальным файлам).

  - `./data:/app/data` — локальная папка → внутрь контейнера.
  - `db-data:/var/lib/postgresql/data` — вольюм/том → внутрь контейнера.

- **`networks`** — Список сетей, к которым подключён контейнер.

- **`depends_on`** — запускать сервис только после указанных зависимостей (НЕ гарантирует полную готовность DB).

### Основные команды

| Команда                              | Описание                                              |
| ------------------------------------ | ----------------------------------------------------- |
| `docker compose up`                  | Запустить все сервисы                                 |
| `docker compose up -d`               | Запустить в фоне (detached)                           |
| `docker compose down`                | Остановить и удалить контейнеры, сети, но не volume’ы |
| `docker compose down -v`             | Удалить контейнеры, сети и volume’ы                   |
| `docker compose build`               | Собрать или пересобрать образы                        |
| `docker compose build --no-cache`    | Пересобрать без кеша                                  |
| `docker compose ps`                  | Показать список контейнеров                           |
| `docker compose logs -f`             | Смотреть логи всех контейнеров                        |
| `docker compose exec <service> bash` | Зайти внутрь контейнера                               |
| `docker compose restart <service>`   | Перезапустить конкретный сервис                       |
| `docker compose stop / start`        | Остановить / запустить без пересоздания               |

### Управление контейнерами

```bash
docker ps                     # список запущенных
docker stop <id>              # остановить
docker restart <id>           # перезапустить
docker logs -f <id>           # логи
docker exec -it <id> bash     # зайти внутрь
docker inspect <id>           # подробная информация
docker stats                  # мониторинг ресурсов
```
