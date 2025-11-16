# Этап 4. Сети — теория.

## 1. Определение сетей в docker-compose

```yaml
networks:
  orders-net:
    driver: bridge
```

- **`orders-net`** — имя сети
- **`driver: bridge`** — тип сети:

  - `bridge` — стандартная внутренняя сеть для контейнеров на одном хосте
  - `host` — использовать сетевой стек хоста
  - `overlay` — для многоконтейнерного взаимодействия между хостами (Swarm)

---

## 2. Подключение сервисов к сети

```yaml
services:
  orders-api:
    image: docker-lab/orders-api:latest
    container_name: backend-orders-api
    build:
      context: .
    environment:
      SOME_ENV_VAR: "some value"
      DEBUG: true
    env_file: ".env"
    networks:
      - orders-net

  orders-web:
    image: orders-frontend
    container_name: frontend-orders
    build:
      context: frontend
    ports:
      - "3001:3000"
    environment:
      BACKEND_HOST: orders-api
    networks:
      - orders-net
```

- **`networks`** — список сетей, к которым подключён контейнер
- Контейнеры в одной сети могут общаться друг с другом по имени сервиса (`orders-api`, `orders-web`) без проброса портов
- **`ports`** нужны только для доступа с хоста или внешней сети

---

## 3. Основные команды для работы с сетями

```bash
docker network ls               # список всех сетей
docker network inspect orders-net  # информация о сети и подключённых контейнерах
docker network create my-net    # создать сеть вручную
docker network connect my-net container_name  # подключить контейнер к сети
docker network disconnect my-net container_name # отключить контейнер
docker network rm my-net        # удалить сеть
```

---

## 4. Особенности взаимодействия frontend и backend

- Контейнеры могут общаться напрямую через **внутренние имена сервисов**, например `orders-web` обращается к `orders-api`
- Для доступа с хоста или из браузера пробрасываем **порты** (`ports: "3001:3000"`)
- Можно создавать несколько сетей для сегментации: фронтенд может быть в сети `frontend-net`, бэкенд — в `backend-net`, а общая сеть `orders-net` для связи между ними

---

## 5. Резюме

| Элемент              | Назначение                                    |
| -------------------- | --------------------------------------------- |
| `networks`           | Определение и настройка сетей                 |
| `driver`             | Тип сети (bridge, host, overlay)              |
| Подключение сервисов | Контейнеры могут общаться по имени сервиса    |
| `ports`              | Проброс портов для доступа с хоста / браузера |
| Команды docker       | `docker network ls/inspect/create/rm`         |
