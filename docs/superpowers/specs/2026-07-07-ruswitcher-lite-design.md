# RuSwitcher Lite — дизайн личной сборки

Дата: 2026-07-07. Ветка: `lite` (форк `rashn/RuSwitcher` → `rkhaierov-sec/RuSwitcher`;
`main` остаётся зеркалом апстрима, вся резка живёт в `lite`).

## Цель

Личная минимальная сборка: **тап по Option → конвертация последнего набранного слова
в другую раскладку + переключение системной раскладки на целевую; повторный тап — откат.**
Ноль сетевых вызовов, ноль обращений к буферу обмена, минимум кода (проще аудит
и доработки под себя). Одноразовый отрыв от апстрима: файлы удаляем смело,
mergeability с upstream не поддерживаем.

## Требования

1. Конвертация последнего слова по тапу триггер-клавиши (движок «буфер нажатий →
   юникод-инжект», без буфера обмена).
2. **После конвертации системная раскладка переключается на раскладку результата**
   (защита от flipio-бага «слово исправил, раскладку не вернул») — отдельный пункт
   смоук-теста.
3. Откат конвертации повторным тапом.
4. Никакого сетевого кода: `grep -r URLSession Sources/` пуст.
5. Никакого clipboard-кода: `grep -r NSPasteboard Sources/` пуст.
6. Триггер и debug-лог настраиваются без GUI через `defaults write` (см. таблицу ниже);
   таблица значений дублируется в README.
7. Debug-лог в файл (`~/Library/Logs/RuSwitcher/`) — выключен по умолчанию, как в оригинале.

## Что удаляем

Файлы целиком:

| Файл | Строк | Причина |
|---|---|---|
| `Sources/RuSwitcher/UpdateChecker.swift` | 329 | единственный сетевой код (version.json + скачивание DMG) |
| `Sources/RuSwitcher/AutoSwitch.swift` | 151 | автоконвертация не нужна |
| `Sources/RuSwitcher/ExceptionListEditor.swift` | 200 | GUI исключений для автоконвертации |
| `Sources/RuSwitcher/CaretIndicator.swift` | 215 | индикатор у каретки не нужен |
| `Sources/RuSwitcher/PerAppLayoutManager.swift` | 65 | память раскладки per-app не нужна |
| `Sources/RuSwitcher/SettingsWindowController.swift` | 604 | GUI настроек; настройки живут в UserDefaults |
| `create_dmg.sh`, `dmg_background.png`, `generate_dmg_background.swift` | — | DMG-поставка не нужна |
| `ruswitcher.rb` | — | Homebrew-формула апстрима |
| `version.json` | — | источник данных UpdateChecker |
| `stats/`, `scripts/stats_report.py` | — | статистика апстрима |
| `generate_icon.swift` | — | генератор иконки; готовые .icns остаются |

Урезаем:

- `TextConverter.swift` (410) — вырезаем clipboard-движок: `savedClipboardItems`,
  `snapshotPasteboard`/restore, `tryCopy`, `pasteText`, `selectBack`-путь и фолбэк
  «выделенный мышью текст». Остаётся движок перепечатки (буфер → backspace →
  юникод-инжект через отдельную `injectQueue`) + вызов `LayoutSwitcher` для
  переключения раскладки на целевую.
- `AppDelegate.swift` (783) — убираем инициализацию и пункты меню удалённых модулей
  (проверка обновлений, настройки-окно, индикатор, автоконвертация, донат-ссылки).
  Меню-бар остаётся: вкл/выкл, статус прав, quit.
- `SettingsManager.swift` (266) — оставляем только ключи: `triggerKey`,
  `triggerRightOnly`, `triggerDoubleTap`, `debugLog`, enabled-флаг.
- `Localization.swift` (1522) — только строки, на которые остались ссылки.

Не трогаем (ядро): `KeyboardMonitor.swift`, `DynamicKeyMapping.swift`, `KeyMapping.swift`,
`LayoutSwitcher.swift`, `KeyCodes.swift`, `main.swift`, `AppRelauncher.swift`,
`Package.swift`, `Info.plist`, `RuSwitcher.entitlements`, `build_app.sh`, иконки.

## Настройка без GUI (фиксируем варианты значений)

Bundle id: `com.ruswitcher.app`. Все команды — с последующим перезапуском приложения.

| Ключ | Значения | Дефолт | Смысл |
|---|---|---|---|
| `com.ruswitcher.triggerKey` | `option` \| `command` \| `control` \| `shift` \| `capsLock` | `option` | триггер-клавиша конвертации |
| `com.ruswitcher.triggerRightOnly` | `true`/`false` | `false` | срабатывать только на правую клавишу пары |
| `com.ruswitcher.triggerDoubleTap` | `true`/`false` | `false` | требовать двойной тап вместо одиночного |
| `com.ruswitcher.debugLog` | `true`/`false` | `false` | лог в `~/Library/Logs/RuSwitcher/ruswitcher.log` |

Пример: `defaults write com.ruswitcher.app com.ruswitcher.triggerKey -string command`

Эта же таблица добавляется в README ветки `lite`.

## Поставка и установка

- Сборка: `./build_app.sh` → `RuSwitcher.app`; копирование в `/Applications` руками.
- Права (руками, через `human_task_ruswitcher_permissions.md`): System Settings →
  Privacy & Security → Accessibility + Input Monitoring.
- CapsLock-переключение раскладки в macOS у пользователя остаётся как есть — сборка
  его не трогает.

## Проверка

1. `swift build` — без ошибок и warning'ов о недостающих символах.
2. `grep -r "URLSession" Sources/` и `grep -r "NSPasteboard" Sources/` — пусто.
3. Смоук-тест (руками, чеклист в human_task): в Chrome (адресная строка + textarea),
   Slack, iTerm2, VS Code, Spotlight:
   - набрать `ghbdtn`, тап Option → `привет`, **системная раскладка стала RU**;
   - повторный тап → обратно `ghbdtn`, раскладка EN;
   - набрать слово, кликнуть мышью в другое место, тап Option → ничего не происходит
     (клик сбрасывает буфер), текст не портится.
4. Отдельно: смена триггера через `defaults write ... triggerKey -string command` +
   перезапуск → работает по Cmd-тапу.

## Риски

- Clipboard-движок в оригинале — фолбэк, когда буфер нажатий пуст (текст выделен мышью
  или тап после клика). После удаления в этих случаях конвертация просто не произойдёт —
  деградация тихая и безопасная (текст не портится). Принято осознанно.
- `AppDelegate` и `Localization` связаны с удаляемыми модулями — риск компиляционных
  хвостов; ловится пунктом проверки 1.
- Ad-hoc/без подписи Developer ID: Gatekeeper может требовать разрешение при первом
  запуске локальной сборки — для личной машины приемлемо.
