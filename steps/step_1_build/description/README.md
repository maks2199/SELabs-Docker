# Этап 1. Сборка docker-образа

## Теория

### Dockerfile Основные инструкции

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

### Docker CLI-команды

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
