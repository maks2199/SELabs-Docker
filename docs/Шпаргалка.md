# Docker шпаргалка

---

## Понятия

- **Image (образ)** – шаблон с приложением и зависимостями.
- **Container (контейнер)** – запущенный экземпляр образа, изолированная среда.
- **docker-compose.yml** — файл, описывающий сервисы (контейнеры), сети и volume’ы.
- **Service (сервис)** — определение контейнера: образ, порты, переменные и т. д.
- **Network (сеть)** — объединяет контейнеры, чтобы они могли общаться.
- **Volume (том)** — постоянное хранилище данных.

---

## Dockerfile Основные инструкции

| Команда       | Описание                           | Пример                                                                  |
| ------------- | ---------------------------------- | ----------------------------------------------------------------------- |
| `FROM`        | Базовый образ                      | `FROM python:3.12-slim`                                                 |
| `WORKDIR`     | Рабочая директория                 | `WORKDIR /app`                                                          |
| `RUN`         | Команда при сборке                 | `RUN pip install -r requirements.txt`                                   |
| `COPY`        | Копирование файлов                 | `COPY ./app /app`                                                       |
| `ENV`         | Переменная окружения               | `ENV PORT=8080`                                                         |
| `USER`        | Пользователь                       | `USER nonroot`                                                          |
| `CMD`         | Команда при запуске                | `CMD ["python", "main.py"]`                                             |
| `EXPOSE`      | Порт, который будет использоваться | `EXPOSE 8080`                                                           |
| `HEALTHCHECK` | Проверка состояния                 | `HEALTHCHECK CMD curl -f http://localhost:8080/health \|     \| exit 1` |

---

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

**`services`** — описание контейнеров приложения
Раздел, где перечисляются все сервисы (контейнеры), которые будут запускаться.

**`image`**
Готовый образ, который нужно скачать и запустить.

**`build`**
Указывает, что образ нужно собрать из Dockerfile.

- **`context`** — директория, в которой лежит Dockerfile.

**`ports`**
Проброс портов: `хост:контейнер`.

**`env_file`**
Файл с переменными окружения, которые будут загружены в контейнер.

**`environment`**
Переменные окружения, передаваемые в контейнер.
Используются для конфигурации базы PostgreSQL.

**`volumes`**
Монтирование директорий (persist data или доступ к локальным файлам).

- `./data:/app/data` — локальная папка → внутрь контейнера.
- `db-data:/var/lib/postgresql/data` — вольюм/том → внутрь контейнера.

**`networks`**
Список сетей, к которым подключён контейнер.

**`depends_on`**
Запускать сервис только после указанных зависимостей (НЕ гарантирует полную готовность DB).

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

## Docker CLI

### Сборка образа

```bash
docker build -f Dockerfile -t my-app:latest .
docker images
```

- `-f` – путь к Dockerfile
- `-t` – имя и тег образа
- `.` – контекст сборки

---

### Запуск контейнера

```bash
docker run --rm -p 8081:8080 -v "$(pwd)/data:/app/data" my-app:latest
```

- `-p host:container` – проброс портов
- `-v host:container` – bind mount
- `--rm` – удалить после остановки
- `-e VAR=value` / `--env-file .env` – переменные окружения
- `--network net` – подключение к сети

---

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

---

### Сети

```bash
docker network create my-net
docker run --network my-net --name backend my-backend
docker run --network my-net --name frontend -p 3000:3000 my-frontend
```

- Контейнеры в одной сети видят друг друга по имени

---

### Маунты и Volume

```bash
# Bind mount
docker run -v /host/path:/container/path my-app

# Volume
docker volume create my-vol
docker run -v my-vol:/app/data my-app
```

- **Bind mount** – доступ к хостовым файлам
- **Volume** – управляется Docker, для персистентных данных

---

### Оптимизация и безопасность

- Не запускать от root: `USER nonroot`
- Ограничение прав:

```bash
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE my-app
```

- Исключаем лишние файлы: `.dockerignore`

```
__pycache__/
*.log
.env
```

- Multistage build для уменьшения образа:

```dockerfile
FROM builder AS build
RUN build-app
FROM python:3.12-slim
COPY --from=build /app /app
```

- Ограничение ресурсов:

```bash
docker run -m 512m --cpus="1.5" my-app
```

---

### Quick Checklist безопасности и диагностики

```bash
docker inspect <image>
docker history <image>
docker scout cves <image>
docker run --rm -it --entrypoint sh <image>
docker logs <container>
```
