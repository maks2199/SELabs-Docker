#!/usr/bin/env python3
"""
Telegram Bot для автоматического распределения IP-адресов студентам.
Получает список участников чата и назначает каждому IP из диапазона 192.168.2.101-120
"""

import os
import json
from typing import Dict, List
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

# Файл для хранения назначенных IP
STORAGE_FILE = "students_ips.json"
IP_BASE = "192.168.2."
IP_START = 101
IP_END = 120


def load_assignments() -> Dict[str, str]:
    """Загружает назначенные IP из файла"""
    if os.path.exists(STORAGE_FILE):
        with open(STORAGE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def save_assignments(assignments: Dict[str, str]):
    """Сохраняет назначенные IP в файл"""
    with open(STORAGE_FILE, 'w', encoding='utf-8') as f:
        json.dump(assignments, f, ensure_ascii=False, indent=2)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик команды /start"""
    await update.message.reply_text(
        "Привет! Я бот для распределения IP-адресов виртуальных машин студентам.\n\n"
        "Команды:\n"
        "/assign - Автоматически назначить IP всем участникам чата\n"
        "/table - Показать таблицу с назначенными IP\n"
        "/reset - Сбросить все назначения\n"
        "/help - Показать справку"
    )


async def assign_ips(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Назначает IP-адреса всем участникам чата"""
    chat_id = update.effective_chat.id
    
    # Загружаем существующие назначения
    assignments = load_assignments()
    
    try:
        # Получаем список участников чата
        chat_members = []
        administrators = await context.bot.get_chat_administrators(chat_id)
        
        for admin in administrators:
            user = admin.user
            if not user.is_bot:  # Исключаемботов
                full_name = user.full_name or user.username or f"User {user.id}"
                user_key = f"{user.id}_{full_name}"
                chat_members.append((user_key, full_name))
        
        # Пытаемся получить обычных участников (может не работать для больших групп)
        # В Telegram Bot API есть ограничения на получение списка всех участников
        # Для больших групп нужен другой подход
        
        if not chat_members:
            await update.message.reply_text(
                "⚠️ Не удалось получить список участников.\n"
                "Убедитесь, что бот является администратором чата."
            )
            return
        
        # Назначаем IP
        next_ip = IP_START
        new_assignments = {}
        
        for user_key, full_name in sorted(chat_members, key=lambda x: x[1]):
            if user_key not in assignments and next_ip <= IP_END:
                assignments[user_key] = f"{IP_BASE}{next_ip}"
                new_assignments[full_name] = f"{IP_BASE}{next_ip}"
                next_ip += 1
        
        # Сохраняем назначения
        save_assignments(assignments)
        
        # Формируем ответ
        if new_assignments:
            response = "✅ IP-адреса назначены:\n\n"
            for name, ip in new_assignments.items():
                response += f"{name}: {ip}\n"
            await update.message.reply_text(response)
        else:
            await update.message.reply_text("ℹ️ Всем участникам уже назначены IP-адреса.")
        
        # Показываем таблицу
        await show_table(update, context)
        
    except Exception as e:
        await update.message.reply_text(f"❌ Ошибка: {str(e)}")


async def show_table(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Показывает таблицу с назначенными IP"""
    assignments = load_assignments()
    
    if not assignments:
        await update.message.reply_text("ℹ️ IP-адреса еще не назначены. Используйте /assign")
        return
    
    # Формируем таблицу в Markdown
    table = "📊 **Таблица распределения IP-адресов:**\n\n"
    table += "```\n"
    table += "| ФИО участника                  | IP-адрес      |\n"
    table += "| ------------------------------ | ------------- |\n"
    
    # Сортируем по имени
    sorted_assignments = []
    for user_key, ip in assignments.items():
        # Извлекаем имя из ключа (формат: "id_ФИО")
        name = user_key.split('_', 1)[1] if '_' in user_key else user_key
        sorted_assignments.append((name, ip))
    
    for name, ip in sorted(sorted_assignments):
        # Ограничиваем длину имени для красивой таблицы
        name_display = name[:30].ljust(30)
        table += f"| {name_display} | {ip}      |\n"
    
    table += "```"
    
    await update.message.reply_text(table, parse_mode='Markdown')


async def reset_assignments(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Сбрасывает все назначения IP"""
    if os.path.exists(STORAGE_FILE):
        os.remove(STORAGE_FILE)
    await update.message.reply_text("✅ Все назначения IP сброшены.")


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Показывает справку"""
    help_text = """
📖 **Справка по командам:**

/start - Приветствие и список команд
/assign - Автоматически назначить IP-адреса всем участникам чата (192.168.2.101-120)
/table - Показать таблицу с уже назначенными IP-адресами
/reset - Сбросить все назначения и начать заново
/help - Показать эту справку

**Примечание:** Бот должен быть администратором группы для получения списка участников.
    """
    await update.message.reply_text(help_text, parse_mode='Markdown')


def main():
    """Запуск бота"""
    # Получаем токен из переменной окружения
    token = os.getenv("TELEGRAM_BOT_TOKEN")
    
    if not token:
        print("❌ Ошибка: Не указан TELEGRAM_BOT_TOKEN")
        print("Создайте файл .env с содержимым:")
        print("TELEGRAM_BOT_TOKEN=your_bot_token_here")
        return
    
    # Создаем приложение
    application = Application.builder().token(token).build()
    
    # Регистрируем обработчики команд
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("assign", assign_ips))
    application.add_handler(CommandHandler("table", show_table))
    application.add_handler(CommandHandler("reset", reset_assignments))
    application.add_handler(CommandHandler("help", help_command))
    
    # Запускаем бота
    print("🤖 Бот запущен...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
