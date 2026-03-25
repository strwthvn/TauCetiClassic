# SS13 Local Station — управление сервером

Сервер: `162.248.164.135:1488`
VPS: `ssh fornex`, путь: `~/ss13/TauCetiClassic`

## Быстрые команды

```bash
ssh fornex
cd ~/ss13/TauCetiClassic
```

| Действие | Команда |
|---|---|
| Статус | `docker compose ps` |
| Логи (live) | `docker compose logs -f ss13` |
| Логи БД | `docker compose logs -f db` |
| Ресурсы | `docker stats --no-stream` |

## Запуск

```bash
docker compose up -d
```

Первый запуск: собирает образ (~40 сек), поднимает MariaDB, импортирует схему, запускает DreamDaemon.

## Остановка

```bash
# Остановить всё (БД + сервер)
docker compose down

# Остановить только игровой сервер (БД продолжит работать)
docker compose stop ss13
```

## Перезапуск

```bash
# Перезапуск сервера (новый раунд)
docker compose restart ss13

# Полный перезапуск (БД + сервер)
docker compose restart
```

## Обновление (git pull + пересборка)

```bash
cd ~/ss13/TauCetiClassic
git fetch upstream
git merge upstream/master
docker compose up -d --build
```

`--build` пересобирает образ. Кэш Docker ускоряет сборку — пересобираются только изменённые слои.

Пуш в свой форк после обновления:
```bash
git push origin master
```

## Смена карты

```bash
# Скопировать json нужной карты в data/next_map.json внутри контейнера
docker compose exec ss13 cp /ss13/maps/stroechka.json /ss13/data/next_map.json
docker compose restart ss13
```

Доступные карты: `stroechka`, `falcon`, `boxstation`, `boxstation_snow`, `gamma`, `gamma_snow`, `delta`, `prometheus`.

## Whitelist — добавить/удалить игрока

Файл: `config/ckey_whitelist.txt` — один ckey на строку.

```bash
# Добавить
echo "nickname" >> config/ckey_whitelist.txt

# Посмотреть список
cat config/ckey_whitelist.txt

# Применить (нужен рестарт)
docker compose restart ss13
```

## Админка

Файл: `config/admins.txt` — формат: `ckey - Rank`

```
Ed1n0rog - Host
```

Ранги: `Host`, `Head Admin`, `Game Master`, `Game Admin`, `Trial Admin`, `Admin Candidate`, `Developer`.

## Конфиги

| Файл | Что настраивает |
|---|---|
| `config/config.txt` | Основные настройки сервера |
| `config/dbconfig.txt` | Подключение к БД (генерируется автоматически) |
| `config/maps.txt` | Ротация и настройки карт |
| `config/game_options.txt` | Баланс: здоровье, скорость, крафт |
| `config/admins.txt` | Список администраторов |
| `config/admin_ranks.txt` | Определения рангов и прав |
| `config/ckey_whitelist.txt` | Whitelist по ckey |
| `.env` | Пароли БД, порт, название сервера |

После изменения конфигов: `docker compose restart ss13`
После изменения кода (`.dm` файлы): `docker compose up -d --build`

## Troubleshooting

```bash
# Сервер крашится / рестартует
docker compose logs ss13 --tail 50

# Проверить БД
docker compose exec db mariadb -u ss13 -pchangeme_ss13 ss13 -e "SHOW TABLES;"

# Зайти внутрь контейнера
docker compose exec ss13 bash

# Полная пересборка с нуля (без кэша)
docker compose build --no-cache && docker compose up -d
```
