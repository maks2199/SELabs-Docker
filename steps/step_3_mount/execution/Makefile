# ═══════════════════════════════════════════════════════════════
# Этап 3: Монтирование — самостоятельная работа
# ═══════════════════════════════════════════════════════════════

.PHONY: compose-up compose-down inspect-volume help
.DEFAULT_GOAL := help

CONTAINER := c-backend-orders-api

GREEN  := $(shell printf '\033[0;32m')
YELLOW := $(shell printf '\033[0;33m')
RED    := $(shell printf '\033[0;31m')
BOLD   := $(shell printf '\033[1m')
NC     := $(shell printf '\033[0m')

define run_cmd
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
	@echo "$(BOLD)$(GREEN)  ▶  $(1)$(NC)"
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
endef

help: ## Показать список команд
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)  Этап 3: Монтирование — самостоятельная работа$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "  $(YELLOW)%-18s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Задание:$(NC)"
	@echo "$(YELLOW)   1. Создать docker-compose.yml в этой директории$(NC)"
	@echo "$(YELLOW)   2. Описать сервис backend:$(NC)"
	@echo "$(YELLOW)      - образ: docker-lab/orders-api:latest$(NC)"
	@echo "$(YELLOW)      - имя контейнера: $(CONTAINER)$(NC)"
	@echo "$(YELLOW)      - контекст сборки: ./backend$(NC)"
	@echo "$(YELLOW)      - порт: 8081:8080$(NC)"
	@echo "$(YELLOW)      - volume для БД: /data/orders.db$(NC)"
	@echo "$(YELLOW)   3. Объявить volume$(NC)"
	@echo "$(YELLOW)   4. Запустить: make compose-up$(NC)"
	@echo "$(YELLOW)   5. Обследовать: make inspect-volume$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

compose-up: ## Собрать и запустить контейнер
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Запуск сервиса из вашего docker-compose.yml$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   --build   Пересобрать образы перед запуском$(NC)"
	@echo "$(YELLOW)   -d        Detached: контейнер работает в фоне$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if [ ! -f docker-compose.yml ]; then \
		echo "$(RED)Файл docker-compose.yml не найден!$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Создайте файл docker-compose.yml в этой директории.$(NC)"; \
		echo "$(YELLOW)Минимальная структура:$(NC)"; \
		echo ""; \
		echo "$(YELLOW)   services:$(NC)"; \
		echo "$(YELLOW)     orders-api:$(NC)"; \
		echo "$(YELLOW)       image: docker-lab/orders-api:latest$(NC)"; \
		echo "$(YELLOW)       container_name: $(CONTAINER)$(NC)"; \
		echo "$(YELLOW)       build:$(NC)"; \
		echo "$(YELLOW)         context: ./backend$(NC)"; \
		echo "$(YELLOW)       ports:$(NC)"; \
		echo "$(YELLOW)         - \"8081:8080\"$(NC)"; \
		echo "$(YELLOW)       volumes:$(NC)"; \
		echo "$(YELLOW)         - appdata:/data/orders.db$(NC)"; \
		echo ""; \
		echo "$(YELLOW)   volumes:$(NC)"; \
		echo "$(YELLOW)     appdata:$(NC)"; \
		exit 1; \
	fi
	$(call run_cmd,docker compose up -d --build)
	@docker compose up -d --build
	@echo ""
	@echo "$(YELLOW)Запущенные контейнеры:$(NC)"
	@echo ""
	$(call run_cmd,docker ps)
	@docker ps

compose-down: ## Остановить и удалить контейнер
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Остановка сервиса$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker compose down)
	@docker compose down

inspect-volume: ## Найти расположение volume в системе
	@docker inspect $(CONTAINER) > /dev/null 2>&1 || ( \
		echo "$(RED)Контейнер $(CONTAINER) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)1. Список всех volumes$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker volume ls)
	@docker volume ls
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)2. Маунты контейнера $(CONTAINER)$(NC)"
	@echo ""
	@echo "$(YELLOW)   Ищите в выводе:$(NC)"
	@echo "$(YELLOW)   \"Type\"        — тип маунта (volume / bind)$(NC)"
	@echo "$(YELLOW)   \"Name\"        — имя volume$(NC)"
	@echo "$(YELLOW)   \"Source\"      — путь на хосте (/var/lib/docker/volumes/...)$(NC)"
	@echo "$(YELLOW)   \"Destination\" — путь внутри контейнера$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker inspect $(CONTAINER) --format '{{json .Mounts}}')
	@docker inspect $(CONTAINER) --format '{{json .Mounts}}' | python3 -m json.tool 2>/dev/null \
		|| docker inspect $(CONTAINER) --format '{{json .Mounts}}'
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)3. Содержимое volume на хосте$(NC)"
	@echo "$(YELLOW)   (требует sudo)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@VOLUME_SOURCE=$$(docker inspect $(CONTAINER) --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Source}}{{end}}{{end}}'); \
	if [ -n "$$VOLUME_SOURCE" ]; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  sudo ls -la $$VOLUME_SOURCE$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		sudo ls -la $$VOLUME_SOURCE; \
	else \
		echo "$(YELLOW)   Volume не найден (возможно, используется bind mount)$(NC)"; \
	fi
