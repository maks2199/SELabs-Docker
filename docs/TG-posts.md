# Серия постов в чате учебной группы

## Пост -7. Инструкция.

Коллеги, всем доброе утро!

Нашу лабораторную работу мы будем проводить на специально подготовленных для слушателей виртуальных машинах. Поэтому, просьба:

✅ Перед лабораторной работой настроить и проверить подключение к виртуальной машине.

🔹 Настроить VSCode

1. Установите VSCode: https://code.visualstudio.com/download
2. Установите расширение RemoteSSH: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh

🔹 Настроить VPN

На Windows/MacOS

1. Установите OpenVPN Connect: https://openvpn.net/client/ → Downloads → Windows → OpenVPN Connect
2. Откройте OpenVPN Connect → File → Import → From local file → выберите **ch_vpn_windows.ovpn** (файл приложил ниже)
3. Подключитесь (Connect → введите логин/пароль при необходимости). Разрешите доступ в брандмауэре Windows (Private и Public).

На Linux

```sh
sudo apt install openvpn resolvconf
sudo openvpn --config ./ch_vpn_linux.ovpn
```

🔹 Настроить подключение к ВМ

1. В левом нижнем углу VSCode нажмите на две стрелочки (Open a remote window)
2. Выберите "Connect to Host..." → "Configure SSH Host..." → выберите файл config
   2.1 \*Возможно файла config до этого не существовало, тогда его нужно создать.
3. Добавьте в config:

```
Host se_labs_user
 HostName 192.168.2.1XX
 User linux
 StrictHostKeyChecking no
 UserKnownHostsFile /dev/null
```

_XX — ваш номер хоста, от 01 до 11_\*

4. Выберите Connect to Host... → Configure SSH Host... → Выбираем se_labs_user
5. Введите пароль: linux

После успешного подключения в терминале VSCode вы будете видеть: linux@localhost:~$

🔗 Подробнее про настройку RemoteSSH: https://code.visualstudio.com/docs/remote/ssh

---

\*_Номер хоста пока что задайте любой от 01 до 11, позже распределим всех по IP-адресам_

## Пост -6. Docker

🐋 Docker – ваш ключ к эффективной разработке и деплою!

Основные преимущества:

1. Мгновенный запуск сложных систем (веб-сервер + БД + кеш) одной командой
2. Управление виртуальной системой через контейнеры (легче виртуализации)
3. Изоляция сервисов предотвращает конфликты зависимостей
4. Повторяемость окружений от разработки до продакшена
   Пример запуска системы за 5 минут:

Создаём docker-compose.yml

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: example
  redis:
    image: redis:alpine
```

Запускаем всё одной командой:
docker compose up -d → система из 3 сервисов готова к работе! 🚀

🔗 Ссылки

- Официальный сайт: https://www.docker.com/
- Официальная документация: https://docs.docker.com/get-started/docker-overview/
- Видео, что такое Docker: https://ya.ru/video/preview/16568526479627771059

💬Вопросы? Пишите в комментарии – разберём ваши кейсы!

## Пост -5: Как установить.

🐋 Я тоже так хочу!

Хочешь попробовать Docker локально? Вот простой план:

1. Перейди на сайт Docker и скачай Docker Desktop для своей ОС (Windows/macOS/Linux): https://docs.docker.com/get-started/introduction/get-docker-desktop/
2. Установи его, следуя инструкциям.
3. Проверь, что всё работает: в терминале запусти docker --version, затем docker run hello-world. Приложение «hello-world» загрузится, запустится в контейнере — и ты увидишь сообщение от Docker.

🔗 Ссылки

- Официальная инструкция по установке Docker desktop: https://docs.docker.com/get-started/introduction/get-docker-desktop/
- Видео. Установка Docker desktop на Windows: https://rutube.ru/video/a3169e2ad9e310877e7c4a00be5fd29f/

💬 Вопросы? Пишите в комментарии!

## Пост -4: Инструменты.

🐋 VSCode — редактор-швейцарский нож!

Visual Studio Code — лёгкий и бесплатный редактор, который стал стандартом для разработчиков.
В нём есть всё: подсветка кода, встроенный терминал, расширения под любые задачи.
Хотите управлять Docker? Установите расширение и контролируйте контейнеры прямо из окна редактора.
Нужно работать на удалённом сервере? Подключайтесь по SSH через VSCode и редактируйте файлы так, будто они у вас на компьютере.

🔗 Ссылки:

- Скачать VSCode: https://code.visualstudio.com/download
- Статья. Инструкция по использованию VSCode: https://practicum.yandex.ru/blog/vsyo-o-visual-studio-code/
- VSCode и Docker: https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers
- VSCode и SSH: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh

## Пост -3: RemoteSSH.

🚀 Ваш VSCode и там, и тут передают!

С помощью расширения Remote - SSH в VSCode можно подключаться к виртуальной машине напрямую.
Настраивается через файл ~/.ssh/config, где прописываем хост, пользователя и ключ.
После подключения открываются все файлы на сервере, а в VSCode появляется терминал — работать можно так, будто все локально.
Быстро, удобно, без лишних копирований!

🔗 Ссылки

- Подробная инструкция. VSCode Remote - SSH: https://code.visualstudio.com/docs/remote/ssh
- Видео. Подключение к хостингу в VS Code с помощью Remote SSH: https://rutube.ru/video/a5cd8a7181f4c13ae25cde97c7e54a88/

## Пост -2: Шпаргалка Linux.

🐧 Linux-шпаргалка для Docker-разработчика

🔹 Навигация:

pwd — где я?

ls -la — список файлов

cd /path — перейти в папку

🔹 Работа с файлами:

cat file.log — показать содержимое

tail -f file.log — следить за логами

grep "error" file.log — искать в тексте

🔹 Горячие клавиши:

⬆️ — повторить предыдущую команду

Ctrl + C — остановить процесс

Ctrl + D — выйти из терминала

Tab — автодополнение

🔗 Ссылки

- Linux Command Cheat Sheet: https://phoenixnap.com/kb/linux-commands-cheat-sheet
- Видео. Терминал Linux: https://rutube.ru/video/cef748180c93d70c90235f4faa17e112/

## Пост -1: Напоминание, проверить доступность подключения к ВМ

Коллеги, добрый день! Напоминаю, что нашу лабораторную работу мы будем проводить на специально подготовленных для слушателей виртуальных машинах. Поэтому, чтобы не задерживаться по техническим вопросам на занятии завтра, просьба заранее:

✅ Настроить и проверить подключение к виртуальной машине.

(Ссылка на пост-инструкцию по настройке ВМ).
