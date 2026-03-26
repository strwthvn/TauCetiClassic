---
name: SS13 TauCetiClassic server project
description: Private SS13 server "Local Station" on VPS — Docker setup, codebase structure, custom whitelist, Stroechka map
type: project
---

## Проект

Приватный SS13 сервер "Local Station" на базе TauCetiClassic (BYOND 516.1663).
Сервер для друзей с whitelist по ckey.

**Why:** Сервер для игры с друзьями, которые переходят с SS14.
**How to apply:** При работе с этим репо — учитывать Docker-инфраструктуру, кастомные изменения в коде (whitelist), и что основная карта — Stroechka.

## Расположение

- VPS: `ssh fornex`, путь: `~/ss13/TauCetiClassic/`
- Форк на GitHub: `strwthvn/TauCetiClassic`
- Remotes: `origin` → форк (SSH через `github-tauceti`), `upstream` → `TauCetiStation/TauCetiClassic`
- Ветка: `master`

## Docker-инфраструктура

Создана с нуля (файлы в корне репо):
- `Dockerfile` — Ubuntu 22.04, BYOND 516.1663 с CDN, i386-библиотеки, `libmysqlclient21:i386` + симлинк для `.so`, компиляция DreamMaker
- `docker-compose.yml` — сервисы `db` (MariaDB 10.11) + `ss13` (BYOND DreamDaemon)
- `docker-entrypoint.sh` — генерация конфигов из env, ожидание БД, запуск DreamDaemon
- `.env` — пароли БД (`changeme_*` — дефолтные, не менялись), порт 1488, название "Local Station"
- `.dockerignore`
- Схема БД `SQL/ss13.sql` автоимпортируется через `/docker-entrypoint-initdb.d/`
- Volumes: `db-data` (MariaDB), `ss13-data` (game data), bind mount `./config:/ss13/config`
- SSH deploy key `~/.ssh/id_tauceti` для пуша в форк (SSH alias `github-tauceti` в `~/.ssh/config`)

## Кастомные изменения в коде

1. **Ckey whitelist** — добавлена система whitelist по ckey:
   - `code/controllers/configuration.dm` — переменные `ckey_whitelist_enabled`, `ckey_whitelist_message`, `ckey_whitelist` + парсинг `config/ckey_whitelist.txt`
   - `code/modules/admin/IsBanned.dm` — проверка в `world/IsBanned()` перед bunker check
   - `config/ckey_whitelist.txt` — файл со списком разрешённых ckey
   - Включается через `CKEY_WHITELIST_ENABLED` в `config/config.txt`

2. **hub.dm** — `world.name = "Local Station"`, `world.status = "Сервер для друзей"`, хаб SS13 включён

3. **Конфиг** (`config/config.txt`):
   - `SERVERNAME Local Station`
   - `SQL_ENABLED`, `ADMIN_LEGACY_SYSTEM`
   - Расы доступны без ограничений по времени (ALIEN_AVAILABLE_BY_TIME закомментирован)
   - OOC работает во время раунда (OOC_ROUND_ONLY закомментирован)
   - USE_ALIEN_JOB_RESTRICTION закомментирован
   - ANTAG_HUD_RESTRICTED оставлен
   - `CKEY_WHITELIST_ENABLED`

4. **Админка**: `config/admins.txt` — `Ed1n0rog - Host`

5. **Карта**: Stroechka (Гефест) — дефолтная в `config/maps.txt`, `data/next_map.json` задаётся внутри контейнера

## Ключевые файлы кодовой базы

- Погода: `code/datums/weather/weather.dm`, `weather_types.dm` (snow_storm для Stroechka)
- Температура: `code/modules/mob/living/carbon/human/life.dm` → `handle_environment()`
- Атмос (ZAS): `code/modules/atmospheric/ZAS/`
- Нагрев: `code/modules/atmospheric/machinery/components/unary_devices/thermomachine.dm`
- Ивенты: `code/modules/events/` + `code/controllers/subsystem/events.dm`
- Враждебные мобы: `code/modules/mob/living/simple_animal/hostile/`
- Работы: `code/game/jobs/` (на Stroechka: CE, Engineer x3, Atmos Tech x3, Tech Assistant x2, Cyborg)
- Скиллы Stroechka: `code/modules/skills/skillset_stroechka.dm` (ULTRA ENGINEER — все навыки)
- Конфиг парсинг: `code/controllers/configuration.dm`
- Подключение: `code/modules/admin/IsBanned.dm`
- Снежные тайлы: `code/game/turfs/turf_snow.dm`

## Гайд

`ss13-guide.md` в корне репо — инструкция по запуску/остановке/обновлению.
