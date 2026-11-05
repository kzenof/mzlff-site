# MZLFF – фан-сайт

Неофициальный многостраничный сайт, посвящённый Илье (MZLFF) и его альтер-эго **Илюха реп**.

Сайт: https://kzenof.github.io/mzlff-site

## Обновление релизов с Яндекс Музыки

Релизы лежат в:

- `mzlff/data/releases.json` + `mzlff/js/releases-data.js`
- `ilyukha-rep/data/releases.json` + `ilyukha-rep/js/releases-data.js`

Страница сначала читает `window.RELEASES_DATA` из `releases-data.js`, иначе делает `fetch` на `data/releases.json`.

### Автообновление (предпочтительно)

Скрипт тянет альбомы из API Яндекс Музыки и перезаписывает оба файла.

**Запускать нужно с компьютера в РФ** — с серверов вне РФ API отвечает HTTP 451.

```powershell
.\scripts\update-and-push-mzlff.ps1
.\scripts\update-and-push-ilyukha-rep.ps1
```

Или вручную:

```bash
python scripts/update_releases.py mzlff
python scripts/update_releases.py ilyukha-rep
```

### Формат одного релиза

```json
{
  "title": "комедия наблюдений",
  "year": 2026,
  "type": "single",
  "cover": "https://avatars.yandex.net/get-music-content/.../400x400",
  "link": "https://music.yandex.ru/album/44550829",
  "yandexId": 44550829,
  "featuring": "Слава КПСС"
}
```

Поля:

| Поле | Обязательно | Значение |
|------|-------------|----------|
| `title` | да | название релиза |
| `year` | да | год |
| `type` | да | `album`, `single` или `ep` |
| `cover` | желательно | URL обложки 400×400 |
| `link` | да | ссылка на альбом в Яндекс Музыке |
| `yandexId` | да | числовой ID альбома |
| `featuring` | нет | другие артисты через запятую |

Корневой объект JSON также содержит `source`, `slug`, `artistId`, `displayName`, `yandexUrl`, `updatedAt`, `releases`.

После правки `releases.json` нужно синхронно обновить `js/releases-data.js` (тот же JSON внутри `window.RELEASES_DATA = ...;`), иначе GitHub Pages покажет старые данные из JS-бандла.
