# MZLFF — фан-сайт

Неофициальный многостраничный сайт, посвящённый Илье (MZLFF) и его альтер-эго **Илюха реп**.

## Обновление релизов с Яндекс Музыки

Релизы подтягиваются скриптом с API Яндекс Музыки. **Запускать нужно с компьютера в РФ** — серверы GitHub блокируются (HTTP 451).

Перед первым запуском убедись, что установлен **Python 3** и настроен **git** с доступом к репозиторию.

Открой PowerShell в папке проекта:

```powershell
cd C:\Users\akalinsky\Documents\mzlff-site
```

### MZLFF

```powershell
.\scripts\update-and-push-mzlff.ps1
```

Что делает скрипт:
1. Загружает релизы артиста MZLFF (ID `6236891`)
2. Записывает в `mzlff/data/releases.json` и `mzlff/js/releases-data.js`
3. Коммитит и пушит изменения, если что-то обновилось

### Илюха реп

```powershell
.\scripts\update-and-push-ilyukha-rep.ps1
```

Что делает скрипт:
1. Загружает релизы **Илюха реп** (ID `25098870`)
2. Записывает в `ilyukha-rep/data/releases.json` и `ilyukha-rep/js/releases-data.js`
3. Коммитит и пушит изменения, если что-то обновилось

### Только загрузить, без git

```powershell
python scripts/update_releases.py mzlff
python scripts/update_releases.py ilyukha-rep
```

## Структура проекта

```
mzlff-site/
├── index.html              # главная
├── gallery.html, bio.html, links.html, about.html
├── css/                    # стили
├── js/                     # общие скрипты (карусель, карточки релизов)
├── scripts/
│   ├── update_releases.py
│   ├── update-and-push-mzlff.ps1
│   └── update-and-push-ilyukha-rep.ps1
├── mzlff/
│   ├── index.html          # страница MZLFF
│   ├── assets/             # фото и обложки
│   ├── data/releases.json
│   └── js/releases-data.js
└── ilyukha-rep/
    ├── index.html          # страница Илюха реп
    ├── data/releases.json
    └── js/releases-data.js
```

Каждый артист в своей папке — так проще не путать релизы и данные.

## GitHub Pages

После `git push` сайт обновится на GitHub Pages (если включён в настройках репозитория). Новые треки на сайте появятся только после запуска одного из скриптов выше.
