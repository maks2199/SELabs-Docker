# Docker Mini-Shpargalka

---

## Понятия

- **Image (образ)** – шаблон с приложением и зависимостями.
- **Container (контейнер)** – запущенный экземпляр образа, изолированная среда.

---

## Dockerfile Основные инструкции

| Команда       | Описание                           | Пример                                                |
| ------------- | ---------------------------------- | ----------------------------------------------------- | --- | ------- |
| `FROM`        | Базовый образ                      | `FROM python:3.12-slim`                               |
| `WORKDIR`     | Рабочая директория                 | `WORKDIR /app`                                        |
| `RUN`         | Команда при сборке                 | `RUN pip install -r requirements.txt`                 |
| `COPY`        | Копирование файлов                 | `COPY ./app /app`                                     |
| `ENV`         | Переменная окружения               | `ENV PORT=8080`                                       |
| `USER`        | Пользователь                       | `USER nonroot`                                        |
| `CMD`         | Команда при запуске                | `CMD ["python", "main.py"]`                           |
| `EXPOSE`      | Порт, который будет использоваться | `EXPOSE 8080`                                         |
| `HEALTHCHECK` | Проверка состояния                 | `HEALTHCHECK CMD curl -f http://localhost:8080/health |     | exit 1` |

---

## Сборка образа

```bash
docker build -f Dockerfile -t my-app:latest .
docker images
```

- `-f` – путь к Dockerfile
- `-t` – имя и тег образа
- `.` – контекст сборки

---

## Запуск контейнера

```bash
docker run --rm -p 8081:8080 -v "$(pwd)/data:/app/data" my-app:latest
```

- `-p host:container` – проброс портов
- `-v host:container` – bind mount
- `--rm` – удалить после остановки
- `-e VAR=value` / `--env-file .env` – переменные окружения
- `--network net` – подключение к сети

---

## Управление контейнерами

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

## Сети

```bash
docker network create my-net
docker run --network my-net --name backend my-backend
docker run --network my-net --name frontend -p 3000:3000 my-frontend
```

- Контейнеры в одной сети видят друг друга по имени

---

## Маунты и Volume

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

## Оптимизация и безопасность

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

## Quick Checklist безопасности и диагностики

```bash
docker inspect <image>
docker history <image>
docker scout cves <image>
docker run --rm -it --entrypoint sh <image>
docker logs <container>
```
