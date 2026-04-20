# ═══════════════════════════════════════════════════════════════
# Этап 4: Сети и тома — самостоятельная работа
# ═══════════════════════════════════════════════════════════════
#
# Задача: создать docker-compose.yml с фронтендом и бэкендом,
# объединить их общей сетью, примонтировать volume для БД.
#
# Запускать из директории: steps/step_4_network/execution/
#
# Цвета:
#   YELLOW — инструкции и подсказки
#   GREEN  — выполняемые команды
#   RED    — ошибки
#   без изменений — вывод команд
#
# ═══════════════════════════════════════════════════════════════

.PHONY: compose-up compose-down inspect monitor status clean help
.DEFAULT_GOAL := help

FRONTEND_CONTAINER := c-frontend-orders
BACKEND_CONTAINER  := c-backend-orders-api
FRONTEND_PORT      := 3001
BACKEND_PORT       := 8081

GREEN  := $(shell printf '\033[0;32m')
YELLOW := $(shell printf '\033[0;33m')
RED    := $(shell printf '\033[0;31m')
BOLD   := $(shell printf '\033[1m')
NC     := $(shell printf '\033[0m')

# Блок с выполняемой командой
define run_cmd
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
	@echo "$(BOLD)$(GREEN)  ▶  $(1)$(NC)"
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
endef

help: ## Показать список команд
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)  Этап 4: Сети и тома — самостоятельная работа$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "  $(YELLOW)%-14s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Задание (коротко):$(NC)"
	@echo "$(YELLOW)   1. Создать docker-compose.yml в этой директории$(NC)"
	@echo "$(YELLOW)   2. Описать сервис frontend:$(NC)"
	@echo "$(YELLOW)      - образ:           docker-lab/orders-frontend$(NC)"
	@echo "$(YELLOW)      - имя контейнера:  $(FRONTEND_CONTAINER)$(NC)"
	@echo "$(YELLOW)      - контекст сборки: ./frontend$(NC)"
	@echo "$(YELLOW)      - порт:            $(FRONTEND_PORT):3000$(NC)"
	@echo "$(YELLOW)      - env:             BACKEND_HOST=orders-api$(NC)"
	@echo "$(YELLOW)      - network:         общая с backend$(NC)"
	@echo "$(YELLOW)   3. Описать сервис backend:$(NC)"
	@echo "$(YELLOW)      - образ:           docker-lab/orders-api:latest$(NC)"
	@echo "$(YELLOW)      - имя контейнера:  $(BACKEND_CONTAINER)$(NC)"
	@echo "$(YELLOW)      - имя сервиса:     orders-api  (DNS-имя в сети)$(NC)"
	@echo "$(YELLOW)      - контекст сборки: ./backend$(NC)"
	@echo "$(YELLOW)      - volume:          для /data/orders.db$(NC)"
	@echo "$(YELLOW)      - network:         общая с frontend$(NC)"
	@echo "$(YELLOW)      - порт наружу НЕ пробрасывать$(NC)"
	@echo "$(YELLOW)   4. Объявить network и volume на верхнем уровне$(NC)"
	@echo ""
	@echo "$(YELLOW)Порядок работы:$(NC)"
	@echo "$(YELLOW)   1. make compose-up$(NC)"
	@echo "$(YELLOW)   2. Открыть в браузере http://<ip-ВМ>:$(FRONTEND_PORT)$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что http://<ip-ВМ>:$(BACKEND_PORT) недоступен$(NC)"
	@echo "$(YELLOW)   4. make inspect$(NC)"
	@echo "$(YELLOW)   5. make compose-down$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

compose-up: ## Собрать и запустить контейнеры
	@if [ ! -f docker-compose.yml ]; then \
		echo "$(RED)Файл docker-compose.yml не найден!$(NC)"; \
		echo "$(YELLOW)Сначала создайте docker-compose.yml в этой директории (см. make help)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Запуск сервисов из docker-compose.yml$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   --build   Пересобрать образы перед запуском$(NC)"
	@echo "$(YELLOW)   -d        Detached: контейнеры работают в фоне$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Откройте в браузере: http://localhost:$(FRONTEND_PORT)$(NC)"
	@echo ""
	$(call run_cmd,docker compose up -d --build)
	@docker compose up -d --build || ( \
		echo ""; \
		echo "$(RED)Запуск завершился с ошибкой$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Частые причины:$(NC)"; \
		echo "$(YELLOW)   Порт $(FRONTEND_PORT) занят       →  docker ps | grep $(FRONTEND_PORT)$(NC)"; \
		echo "$(YELLOW)   Образ не собран       →  убедитесь, что образы собраны на предыдущих этапах$(NC)"; \
		echo "$(YELLOW)   Ошибка в compose.yml  →  посмотрите на строку с ошибкой выше$(NC)"; \
		exit 1 \
	)
	@echo ""
	@echo "$(YELLOW)Запущенные контейнеры:$(NC)"
	@echo ""
	$(call run_cmd,docker ps)
	@docker ps

compose-down: ## Остановить и удалить контейнеры
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   без флагов  — остановить и удалить контейнеры$(NC)"
	@echo "$(YELLOW)   -v          — также удалить volumes$(NC)"
	@echo "$(YELLOW)   --rmi all   — также удалить образы$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker compose down)
	@docker compose down

inspect: ## Обследовать сеть и volume
	@docker inspect $(BACKEND_CONTAINER) > /dev/null 2>&1 || ( \
		echo "$(RED)Контейнер $(BACKEND_CONTAINER) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)1. Список сетей Docker$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker network ls)
	@docker network ls
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)2. Сеть, в которой работают контейнеры$(NC)"
	@echo ""
	@echo "$(YELLOW)   Ищите в выводе:$(NC)"
	@echo "$(YELLOW)   \"Name\"        — имя сети$(NC)"
	@echo "$(YELLOW)   \"Driver\"      — обычно bridge$(NC)"
	@echo "$(YELLOW)   \"Containers\"  — какие контейнеры подключены$(NC)"
	@echo "$(YELLOW)                   (должны быть оба: frontend и backend)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@NET_NAME=$$(docker inspect $(BACKEND_CONTAINER) --format '{{range $$k, $$v := .NetworkSettings.Networks}}{{$$k}} {{end}}' | awk '{print $$1}'); \
	if [ -z "$$NET_NAME" ]; then \
		echo "$(RED)Не удалось определить сеть контейнера $(BACKEND_CONTAINER)$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
	echo "$(BOLD)$(GREEN)  ▶  docker network inspect $$NET_NAME$(NC)"; \
	echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
	docker network inspect $$NET_NAME | python3 -m json.tool 2>/dev/null \
		|| docker network inspect $$NET_NAME
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)3. Проверка DNS внутри сети$(NC)"
	@echo "$(YELLOW)   frontend должен резолвить backend по имени сервиса$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker exec $(FRONTEND_CONTAINER) getent hosts orders-api)
	@docker exec $(FRONTEND_CONTAINER) getent hosts orders-api 2>/dev/null \
		|| echo "$(YELLOW)   (getent недоступен в контейнере — пропускаем)$(NC)"
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)4. Список всех volumes$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker volume ls)
	@docker volume ls
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)5. Маунты контейнера $(BACKEND_CONTAINER)$(NC)"
	@echo ""
	@echo "$(YELLOW)   Ищите в выводе:$(NC)"
	@echo "$(YELLOW)   \"Type\"        — тип маунта (volume / bind)$(NC)"
	@echo "$(YELLOW)   \"Name\"        — имя volume$(NC)"
	@echo "$(YELLOW)   \"Source\"      — путь на хосте (/var/lib/docker/volumes/...)$(NC)"
	@echo "$(YELLOW)   \"Destination\" — путь внутри контейнера$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker inspect $(BACKEND_CONTAINER) --format '{{json .Mounts}}')
	@docker inspect $(BACKEND_CONTAINER) --format '{{json .Mounts}}' | python3 -m json.tool 2>/dev/null \
		|| docker inspect $(BACKEND_CONTAINER) --format '{{json .Mounts}}'
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)6. Содержимое volume на хосте$(NC)"
	@echo "$(YELLOW)   (требует sudo)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@VOLUME_SOURCE=$$(docker inspect $(BACKEND_CONTAINER) --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Source}}{{end}}{{end}}'); \
	if [ -n "$$VOLUME_SOURCE" ]; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  sudo ls -la $$VOLUME_SOURCE$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		sudo ls -la $$VOLUME_SOURCE; \
	else \
		echo "$(YELLOW)   Volume не найден (возможно, используется bind mount)$(NC)"; \
	fi

monitor: ## Обследовать контейнеры (inspect, exec, top, stats)
	@docker inspect $(BACKEND_CONTAINER) > /dev/null 2>&1 || ( \
		echo "$(RED)Контейнер $(BACKEND_CONTAINER) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)
	@docker inspect $(FRONTEND_CONTAINER) > /dev/null 2>&1 || ( \
		echo "$(RED)Контейнер $(FRONTEND_CONTAINER) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)1. Конфигурация контейнеров$(NC)"
	@echo ""
	@echo "$(YELLOW)   Ищите в выводе:$(NC)"
	@echo "$(YELLOW)   \"Env\"    — переменные окружения контейнера$(NC)"
	@echo "$(YELLOW)   \"Cmd\"    — стартовая команда контейнера$(NC)"
	@echo "$(YELLOW)   \"Image\"  — образ, с которым запущен контейнер$(NC)"
	@echo "$(YELLOW)   \"Ports\"  — проброс портов$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker inspect $(FRONTEND_CONTAINER) $(BACKEND_CONTAINER))
	@docker inspect $(FRONTEND_CONTAINER) $(BACKEND_CONTAINER)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)2. Файлы внутри контейнеров$(NC)"
	@echo "$(YELLOW)   WORKDIR в Dockerfile: /app$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker exec $(FRONTEND_CONTAINER) ls /app)
	@docker exec $(FRONTEND_CONTAINER) ls /app
	@echo ""
	$(call run_cmd,docker exec $(BACKEND_CONTAINER) ls /app)
	@docker exec $(BACKEND_CONTAINER) ls /app
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)3. Процессы внутри контейнеров$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker top $(FRONTEND_CONTAINER))
	@docker top $(FRONTEND_CONTAINER)
	@echo ""
	$(call run_cmd,docker top $(BACKEND_CONTAINER))
	@docker top $(BACKEND_CONTAINER)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)4. Потребление ресурсов$(NC)"
	@echo ""
	@echo "$(YELLOW)   --no-stream — показать снимок и выйти$(NC)"
	@echo "$(YELLOW)   без флага   — интерактивная таблица (Ctrl+C выход)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker stats --no-stream $(FRONTEND_CONTAINER) $(BACKEND_CONTAINER))
	@docker stats --no-stream $(FRONTEND_CONTAINER) $(BACKEND_CONTAINER)

status: ## Показать образы, контейнеры, вольюмы и сети
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Docker-образы:$(NC)"
	@echo ""
	$(call run_cmd,docker images)
	@docker images
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Запущенные контейнеры:$(NC)"
	@echo ""
	$(call run_cmd,docker ps)
	@docker ps
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Docker-вольюмы:$(NC)"
	@echo ""
	$(call run_cmd,docker volume ls)
	@docker volume ls
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Docker-сети:$(NC)"
	@echo ""
	$(call run_cmd,docker network ls)
	@docker network ls
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Совет: docker ps -a — показать все контейнеры (включая остановленные)$(NC)"

clean: ## Остановить стек, удалить образы и вольюмы
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Полная очистка стека:$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   -v                — удалить объявленные в compose вольюмы$(NC)"
	@echo "$(YELLOW)   --rmi local       — удалить образы, собранные локально (build:)$(NC)"
	@echo "$(YELLOW)   --remove-orphans  — удалить контейнеры-сироты$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker compose down -v --rmi local --remove-orphans)
	@docker compose down -v --rmi local --remove-orphans
