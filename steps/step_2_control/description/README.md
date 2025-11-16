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
