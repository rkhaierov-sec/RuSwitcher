# RuSwitcher (lite, личная сборка)

<p align="center">
  <img src="icon.png" width="128" alt="RuSwitcher icon">
</p>

<p align="center">
  <b>Минимальный переключатель раскладки клавиатуры для macOS</b><br>
  Личный форк <a href="https://github.com/rashn/RuSwitcher">rashn/RuSwitcher</a> (MIT), урезанный до одной функции
</p>

---

## Что это

Личная урезанная сборка апстрима [rashn/RuSwitcher](https://github.com/rashn/RuSwitcher) (MIT) —
без сети, без GUI настроек, без лишних режимов. Собирается из исходников только для себя.

Набрали `ghbdtn` вместо «привет»? Нажмите триггер (по умолчанию **Option ⌥**) — RuSwitcher
конвертирует последнее набранное слово и переключает системную раскладку. Нажмите триггер ещё
раз — конвертация отменяется.

## Что вырезано относительно апстрима

- Проверка обновлений и любой сетевой код (`UpdateChecker`, `version.json`).
- Резервный движок конвертации через буфер обмена (только прямой ввод Unicode).
- Автоматическая конвертация по ходу набора (auto-conversion).
- Режим удалённого стола (Apple Screen Sharing).
- Флаг раскладки у текстового курсора (caret indicator).
- Память раскладки по приложению (per-app layout memory).
- GUI-окно настроек — конфигурация только через `defaults write`.
- Поставка: DMG, Homebrew tap, сбор статистики использования.

## Что осталось

- Один триггер (клавиша или комбо) → конвертация последнего слова + переключение системной
  раскладки.
- Повторный тап того же триггера → отмена (undo).
- Вся настройка — через `defaults write`, без UI.

## Сборка

```bash
git clone https://github.com/rkhaierov-sec/RuSwitcher.git
cd RuSwitcher
./build_app.sh
cp -R RuSwitcher.app /Applications/
```

Требуется macOS 13+ и Xcode Command Line Tools. `build_app.sh` подписывает бинарь Developer ID
сертификатом, зашитым в скрипт (апстримный) — при сборке под свой Apple ID замените
`SIGN_ID` в `build_app.sh` на свой, либо используйте ad-hoc подпись (`codesign --force --deep -s -`).

## Разрешения

При первом запуске macOS запросит:

1. **Accessibility** — для отправки CGEvent (Backspace + юникод-вставка) при перепечатке слова.
2. **Input Monitoring** — для отслеживания нажатий клавиш.

## Конфигурация

Настроек-GUI нет — только `defaults write`. Домен — `com.ruswitcher.app`, ключи — с префиксом
`com.ruswitcher.` (передаются вторым аргументом целиком, включая префикс).

| Ключ (префикс com.ruswitcher.) | Значения | Дефолт | Смысл |
|---|---|---|---|
| triggerKey | option \| command \| control \| shift \| capsLock | option | триггер конвертации |
| triggerRightOnly | true/false | false | только правая клавиша пары |
| triggerDoubleTap | true/false | false | двойной тап вместо одиночного |
| autoSwitch | true/false | true | мастер-выключатель конвертации |
| debugLog | true/false | false | лог в ~/Library/Logs/RuSwitcher/ |
| launchAtLogin | true/false | false | автозапуск при логине |
| keySound | true/false | false | звук при конвертации |
| monochromeIcon | true/false | false | монохромная иконка меню-бара |
| layout1ID / layout2ID | id источников ввода | "" (авто) | пара раскладок вручную |

Пример: `defaults write com.ruswitcher.app com.ruswitcher.triggerKey -string command` (+
перезапуск приложения).

Помимо таблицы в коде остаются ещё два внутренних ключа (`autoConvert`, `remoteDesktopMode`) —
это заглушки для ядра после выпиливания их UI в этой сборке, всегда `false`, без публичного
интерфейса и не поддерживаются.

## Технические детали

- `CGEventTap` (passive, только чтение) для мониторинга клавиатуры.
- `UCKeyTranslate` (Carbon) для маппинга символов между любой парой раскладок.
- `CGEvent.keyboardSetUnicodeString` для прямой печати сконвертированного текста — без буфера
  обмена.
- `AXIsProcessTrusted` для проверки разрешения Accessibility.
- `SMAppService` для управления автозапуском.

## Лицензия

[MIT](LICENSE) — унаследована от апстрима.
