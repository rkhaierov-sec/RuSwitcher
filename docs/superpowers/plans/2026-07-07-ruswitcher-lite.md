# RuSwitcher Lite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Урезать форк RuSwitcher (ветка `lite`) до личной сборки: тап по триггеру → конвертация последнего слова + переключение раскладки, откат повторным тапом; ноль сети, ноль clipboard, без GUI-настроек.

**Architecture:** Работа — почти только удаление: 6 файлов целиком, clipboard-движок из TextConverter, хвосты в AppDelegate/SettingsManager/Localization. Ядро (KeyboardMonitor, DynamicKeyMapping, KeyMapping, LayoutSwitcher, KeyCodes) не трогаем. После каждой задачи проект собирается.

**Tech Stack:** Swift 6, SPM (`swift build`), macOS 13+. Тестового таргета в апстриме нет; поведение — удаление фич, поэтому цикл проверки каждой задачи: `swift build` зелёный + grep-инварианты + финальный ручной смоук-тест по чеклисту (задача 9). Юнит-тесты не добавляем (YAGNI для личной сборки, ядро не меняется).

**Спека:** `docs/superpowers/specs/2026-07-07-ruswitcher-lite-design.md`

## Global Constraints

- Рабочая директория: `/Users/ruzal/sandbox/test/RuSwitcher`, ветка `lite`.
- После КАЖДОЙ задачи: `swift build` завершается успешно (`Build complete!`).
- Не трогаем: `KeyboardMonitor.swift`, `DynamicKeyMapping.swift`, `KeyMapping.swift`, `LayoutSwitcher.swift`, `KeyCodes.swift`, `main.swift`, `AppRelauncher.swift`, `Package.swift`, `Info.plist`, `RuSwitcher.entitlements`, `build_app.sh`, иконки (`RuSwitcher.icns`, `RuSwitcher.iconset`, `icon.png`, `Assets.xcassets`).
- Финальные инварианты: `grep -rn "URLSession" Sources/` пуст; `grep -rn "NSPasteboard" Sources/` пуст.
- Ключи UserDefaults, которые ДОЛЖНЫ остаться: `autoSwitch`, `layout1ID`, `layout2ID`, `debugLog`, `launchAtLogin`, `interfaceLanguage`, `permissionsWereGranted`, `triggerKey`, `triggerRightOnly`, `triggerDoubleTap`, `keySound` (используется KeyboardMonitor — ядро не трогаем), `monochromeIcon` (используется отрисовкой иконки). Все — с префиксом `com.ruswitcher.`.
- Коммиты — после каждой задачи, сообщение по-русски, футер `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

### Task 1: Выпилить UpdateChecker (весь сетевой код)

**Files:**
- Delete: `Sources/RuSwitcher/UpdateChecker.swift`, `version.json`
- Modify: `Sources/RuSwitcher/AppDelegate.swift` (вызовы + таймер + пункт меню), `Sources/RuSwitcher/SettingsManager.swift` (ключи обновлений)

**Interfaces:**
- Consumes: —
- Produces: `Sources/` без единого `URLSession`; `AppDelegate` без `updateCheckTimer`, `checkUpdates`.

- [ ] **Step 1: Удалить файлы**

```bash
cd /Users/ruzal/sandbox/test/RuSwitcher
git rm Sources/RuSwitcher/UpdateChecker.swift version.json
```

- [ ] **Step 2: Найти все хвосты**

Run: `grep -n "UpdateChecker\|updateCheckTimer\|checkUpdates\|skippedVersion\|lastUpdateCheck" Sources/RuSwitcher/*.swift`
Ожидаемые места: `AppDelegate.swift` строки ~13 (`updateCheckTimer`), ~24 (`UpdateChecker.checkOnLaunch()`), ~26-30 (Timer с `checkPeriodic`), ~535-537 (пункт меню `updateItem`), ~756 (`@objc checkUpdates` + `UpdateChecker.checkNow()`); `SettingsManager.swift` ключи `skippedVersion`, `lastUpdateCheck`, `checkUpdatesEnabled` и их computed-свойства (~66-94).

- [ ] **Step 3: Удалить каждый найденный хвост** — свойство `updateCheckTimer`, вызовы `checkOnLaunch/checkPeriodic/checkNow`, Timer-блок, `@objc private func checkUpdates`, пункт меню `updateItem` (3 строки + addItem), computed-свойства и ключи `skippedVersion`/`lastUpdateCheck`/`checkUpdatesEnabled` в `SettingsManager.swift`. Строки из L10n (`menuCheckUpdates` и update-диалоги) пока не трогать — общая чистка Localization в задаче 7.

- [ ] **Step 4: Проверить сборку и инвариант**

Run: `swift build 2>&1 | tail -3 && grep -rn "URLSession" Sources/ | wc -l`
Expected: `Build complete!` и `0`

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "lite: выпилить UpdateChecker — ноль сетевого кода

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Выпилить автоконвертацию и remote-desktop-режим

**Files:**
- Delete: `Sources/RuSwitcher/AutoSwitch.swift`, `Sources/RuSwitcher/ExceptionListEditor.swift`
- Modify: `Sources/RuSwitcher/AppDelegate.swift`, `Sources/RuSwitcher/SettingsManager.swift`

**Interfaces:**
- Consumes: `textConverter.convert(wordKeys:prevWordKeys:boundaryCount:) -> Bool`, `textConverter.reconvert() -> Bool`, `keyboardMonitor.markConverted()`, `LayoutSwitcher.switchToOpposite()` — сигнатуры не меняются.
- Produces: `AppDelegate.startMonitoring()` с колбэками ровно в форме из Step 3; `grep AutoSwitchPolicy` по Sources пуст.

- [ ] **Step 1: Удалить файлы**

```bash
git rm Sources/RuSwitcher/AutoSwitch.swift Sources/RuSwitcher/ExceptionListEditor.swift
```

- [ ] **Step 2: Найти хвосты**

Run: `grep -n "AutoSwitchPolicy\|autoConvert\|handleAutoConvert\|onWordBoundary\|lastAutoConverted\|offeredExceptionWords\|offerException\|remoteDesktop\|RemoteDesktop\|deniedApps\|deniedWords\|alwaysConvert" Sources/RuSwitcher/*.swift | grep -v "^Sources/RuSwitcher/KeyboardMonitor"`
KeyboardMonitor в результатах быть не должно (если появился — остановиться и разобраться: ядро не трогаем).

- [ ] **Step 3: Переписать колбэки триггера в `startMonitoring()`** — убрать блоки `if AutoSwitchPolicy.shouldDeferToRemoteClient {...}` и `self.lastAutoConverted = nil` / `self.offerExceptionAfterUndo()`. Итоговый вид:

```swift
        if !keyboardMonitor.start(
            onAltTap: { [weak self] in
                guard let self else { return }
                guard SettingsManager.shared.autoSwitchEnabled else { return }
                let keys = self.keyboardMonitor.currentWordKeys
                let prevKeys = self.keyboardMonitor.prevWordKeys
                let bc = self.keyboardMonitor.boundaryCount
                if self.textConverter.convert(wordKeys: keys, prevWordKeys: prevKeys, boundaryCount: bc) {
                    self.keyboardMonitor.markConverted()
                    LayoutSwitcher.switchToOpposite()
                    self.updateStatusIcon()
                }
            },
            onAltReconvert: { [weak self] in
                guard let self else { return }
                guard SettingsManager.shared.autoSwitchEnabled else { return }
                if self.textConverter.reconvert() {
                    self.keyboardMonitor.markConverted()
                    LayoutSwitcher.switchToOpposite()
                    self.updateStatusIcon()
                }
            }
        ) {
```

- [ ] **Step 4: Удалить остальные хвосты в AppDelegate** — `handleAutoConvert()` целиком (~строки 341-399), строку `keyboardMonitor.onWordBoundary = ...`, секцию `// MARK: - Learn-from-undo` (`lastAutoConverted`, `offeredExceptionWords`, `offerExceptionAfterUndo`), `offerAutoConvertIfNeeded()` и его вызов, `@objc toggleAutoConvert` и `@objc toggleRemoteDesktop`, пункты меню `autoConvertItem` и блок `if SettingsManager.shared.showRemoteDesktopBeta {...}`.

- [ ] **Step 5: Удалить ключи в SettingsManager** — `autoConvert`, `remoteDesktopMode`, `showRemoteDesktopBeta`, `autoConvertOffered`, `deniedAppsAdded`, `deniedAppsRemoved`, `deniedWords`, `alwaysConvertWords` (ключи + computed-свойства, включая свойства с логикой `AutoSwitchPolicy.defaultDeniedApps` на ~строках 195-215).

- [ ] **Step 6: Проверить сборку**

Run: `swift build 2>&1 | tail -3 && grep -rn "AutoSwitchPolicy" Sources/ | wc -l`
Expected: `Build complete!` и `0`

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "lite: выпилить автоконвертацию и remote-desktop-режим

Ручной триггер: конвертация + переключение раскладки, откат повторным тапом.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Выпилить CaretIndicator

**Files:**
- Delete: `Sources/RuSwitcher/CaretIndicator.swift`
- Modify: `Sources/RuSwitcher/AppDelegate.swift`, `Sources/RuSwitcher/SettingsManager.swift`

**Interfaces:**
- Produces: `grep -i caret` по Sources пуст (кроме, возможно, слов в комментариях ядра — их не трогать).

- [ ] **Step 1:** `git rm Sources/RuSwitcher/CaretIndicator.swift`
- [ ] **Step 2:** Run: `grep -n "caretIndicator\|CaretIndicator\|syncCaretIndicator\|caretFlag\|onUserInput" Sources/RuSwitcher/AppDelegate.swift Sources/RuSwitcher/SettingsManager.swift` — удалить: свойство `caretIndicator` (~15), `lastFlagShown` НЕ трогать (это иконка меню-бара), вызовы `syncCaretIndicator()` (~62, ~320, ~722), функцию `syncCaretIndicator()` (~685), строку `keyboardMonitor.onUserInput = ...`, `@objc toggleCaretFlag` + пункт меню `caretFlagItem`, ключ и свойство `caretFlag` в SettingsManager. Замечание: `onUserInput` — публичный колбэк KeyboardMonitor; сам KeyboardMonitor не редактировать (неприсвоенный опциональный колбэк — это ок).
- [ ] **Step 3:** Run: `swift build 2>&1 | tail -3` — Expected: `Build complete!`
- [ ] **Step 4:**

```bash
git add -A && git commit -m "lite: выпилить индикатор у каретки

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Выпилить PerAppLayoutManager

**Files:**
- Delete: `Sources/RuSwitcher/PerAppLayoutManager.swift`
- Modify: `Sources/RuSwitcher/AppDelegate.swift`, `Sources/RuSwitcher/SettingsManager.swift`

- [ ] **Step 1:** `git rm Sources/RuSwitcher/PerAppLayoutManager.swift`
- [ ] **Step 2:** Run: `grep -n "perAppLayout\|PerAppLayout\|startPerAppLayout" Sources/RuSwitcher/*.swift` — удалить: свойство `perAppLayoutManager` (~10), `startPerAppLayout()` (~95) и его вызовы (в `startMonitoring` блок `if SettingsManager.shared.perAppLayout {...}`), колбэк `settingsController.onPerAppLayoutChanged` (~39-42; если Task 5 ещё не сделан — просто удалить блок), ключ и свойство `perAppLayout` в SettingsManager.
- [ ] **Step 3:** Run: `swift build 2>&1 | tail -3` — Expected: `Build complete!`
- [ ] **Step 4:**

```bash
git add -A && git commit -m "lite: выпилить память раскладки per-app

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: Выпилить окно настроек и упростить меню

**Files:**
- Delete: `Sources/RuSwitcher/SettingsWindowController.swift`
- Modify: `Sources/RuSwitcher/AppDelegate.swift`, `Sources/RuSwitcher/SettingsManager.swift`

**Interfaces:**
- Produces: меню-бар финального вида: версия / вкл-выкл / проверить права / выйти. `AppDelegate` без `settingsController`.

- [ ] **Step 1:** `git rm Sources/RuSwitcher/SettingsWindowController.swift`
- [ ] **Step 2:** Run: `grep -n "settingsController\|setupSettingsCallbacks\|openSettings\|openDonate\|openGitHub\|donateURL\|githubURL\|layoutMenuItems\|menuWillOpen\|keySoundItem\|monoIconItem\|toggleKeySound\|toggleMonoIcon\|offerLaunchAtLogin\|launchAtLoginAsked" Sources/RuSwitcher/*.swift`
- [ ] **Step 3: Удалить в AppDelegate** — свойство `settingsController` (~9), `setupSettingsCallbacks()` целиком и вызов, `@objc openSettings/openDonate/openGitHub`, `offerLaunchAtLoginIfNeeded()` целиком и вызов (автозагрузку включаем через `defaults write`, `syncLoginItem()` остаётся), список раскладок в меню (`layoutMenuItems()`, `menuWillOpen`, `menu.delegate = self` и соответствие протоколу `NSMenuDelegate`, если объявлено), пункты меню и тогглеры `keySoundItem`/`toggleKeySound`, `monoIconItem`/`toggleMonoIcon` (сами КЛЮЧИ `keySound`/`monochromeIcon` в SettingsManager ОСТАВИТЬ — их читают KeyboardMonitor и отрисовка иконки; управление — `defaults write`).
- [ ] **Step 4: Переписать `rebuildMenu()`** в финальный вид:

```swift
    private func rebuildMenu() {
        let menu = NSMenu()

        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let verItem = NSMenuItem(title: "RuSwitcher lite \(ver)", action: nil, keyEquivalent: "")
        verItem.isEnabled = false
        menu.addItem(verItem)
        menu.addItem(NSMenuItem.separator())

        let autoItem = NSMenuItem(title: L10n.menuAutoSwitch, action: #selector(toggleAutoSwitch), keyEquivalent: "")
        autoItem.target = self
        autoItem.state = SettingsManager.shared.autoSwitchEnabled ? .on : .off
        menu.addItem(autoItem)

        let permItem = NSMenuItem(title: L10n.menuCheckPermissions, action: #selector(recheckPermissions), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L10n.menuQuit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }
```

В `@objc toggleAutoSwitch` убрать строку `settingsController.updateAutoSwitchState(enabled)`.

- [ ] **Step 5: Удалить в SettingsManager** — свойства `donateURL`, `githubURL` (+ `githubOwner`/`githubRepo`, если больше никем не используются: проверить `grep -n "githubOwner\|githubRepo" Sources/`), ключ и свойство `launchAtLoginAsked`.
- [ ] **Step 6:** Run: `swift build 2>&1 | tail -3` — Expected: `Build complete!`
- [ ] **Step 7:**

```bash
git add -A && git commit -m "lite: выпилить окно настроек, минимальное меню

Настройки триггера/звука/иконки — через defaults write (см. README).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: Вырезать clipboard-движок из TextConverter

**Files:**
- Modify: `Sources/RuSwitcher/TextConverter.swift`

**Interfaces:**
- Consumes: вызовы из AppDelegate (Task 2 Step 3): `convert(wordKeys:prevWordKeys:boundaryCount:) -> Bool`, `reconvert() -> Bool` — сигнатуры сохранить.
- Produces: `grep NSPasteboard Sources/` пуст; `TextConverter` только с буферным движком.

- [ ] **Step 1: Удалить clipboard-методы и состояние** — `convertViaClipboard(...)`, `reconvertViaClipboard()`, `isFocusedElementEditable()`, `snapshotPasteboard`/`restorePasteboard`-логику (поля `savedClipboardItems`, `clipboardRestoreWork`), `tryCopy(...)`, `pasteText(...)`, `selectBack(...)`, поля `lastConvertedCount`, `lastBoundaryCount`, флаг `lastWasBuffer` (движок теперь один). Найти точные границы: `grep -n "func \|private var \|private let " Sources/RuSwitcher/TextConverter.swift`.
- [ ] **Step 2: Заменить фолбэки в `convert(...)`** — обе ветки, возвращавшие `convertViaClipboard(...)` (пустой буфер; `DynamicKeyMapping.convertKeys` вернул nil), заменить на:

```swift
            rslog("buffer convert: no typed buffer — skip (clipboard engine removed in lite)")
            return false
```

и

```swift
            rslog("buffer convert: layouts not resolved — skip (clipboard engine removed in lite)")
            return false
```

- [ ] **Step 3: Упростить `reconvert()`** — убрать `if lastWasBuffer` / `return reconvertViaClipboard()`, оставить только буферную ветку (guard на `lastConverted.isEmpty`, свап `lastOriginal`/`lastConverted`, инжект через `injectQueue`).
- [ ] **Step 4: Проверить инварианты и сборку**

Run: `grep -rn "NSPasteboard\|pasteboard" Sources/ | wc -l && swift build 2>&1 | tail -3`
Expected: `0` и `Build complete!`

- [ ] **Step 5:**

```bash
git add -A && git commit -m "lite: вырезать clipboard-движок — только буферная перепечатка

Пустой буфер (клик мышью) -> тихий no-op вместо фолбэка через Cmd+C/Cmd+V.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: Чистка Localization и финальный SettingsManager

**Files:**
- Modify: `Sources/RuSwitcher/Localization.swift`, `Sources/RuSwitcher/SettingsManager.swift`

- [ ] **Step 1: Найти мёртвые строки локализации** — у каждого computed-свойства `L10n` вида `static var x: String { s("key") }` проверить использование:

```bash
for name in $(grep -o 'static var [a-zA-Z0-9]*' Sources/RuSwitcher/Localization.swift | awk '{print $3}'); do
  n=$(grep -rn "L10n\.$name\b" Sources/RuSwitcher/*.swift | grep -v Localization.swift | wc -l)
  [ "$n" -eq 0 ] && echo "UNUSED: $name"
done
```

- [ ] **Step 2:** Удалить все UNUSED-свойства и соответствующие им записи словарей переводов в `Localization.swift` (ключи вида `"menu.autoConvert"`, `"settings.*"`, update-диалоги и т.п.). Функции локализации с параметрами (если есть, вида `static func x(_:)`) проверить тем же grep-ом вручную.
- [ ] **Step 3: Сверить финальный список ключей SettingsManager** с Global Constraints (12 ключей). Run: `grep -c "static let" Sources/RuSwitcher/SettingsManager.swift` — Expected: `12`. Если больше — найти и удалить лишние, если меньше — проверить, не удалено ли нужное (сверить поимённо).
- [ ] **Step 4:** Run: `swift build 2>&1 | tail -3` — Expected: `Build complete!`
- [ ] **Step 5:**

```bash
git add -A && git commit -m "lite: почистить локализацию и ключи настроек

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: Убрать файлы поставки, README для lite, финальная проверка

**Files:**
- Delete: `create_dmg.sh`, `dmg_background.png`, `generate_dmg_background.swift`, `generate_icon.swift`, `ruswitcher.rb`, `stats/`, `scripts/stats_report.py`
- Modify: `README.md`

- [ ] **Step 1:**

```bash
git rm create_dmg.sh dmg_background.png generate_dmg_background.swift generate_icon.swift ruswitcher.rb
git rm -r stats scripts
```

- [ ] **Step 2: Проверить build_app.sh на ссылки на удалённое** — Run: `grep -n "version.json\|stats\|create_dmg\|generate_" build_app.sh` — Expected: пусто. Если не пусто — удалить эти строки из скрипта.
- [ ] **Step 3: Переписать README.md** — шапка о том, что это личная lite-сборка (ссылка на апстрим rashn/RuSwitcher, MIT), что вырезано (сеть, clipboard, автоконвертация, GUI-настроек), сборка (`./build_app.sh`, копирование в /Applications), и таблица конфигурации (скопировать из спеки, добавить `launchAtLogin`, `keySound`, `monochromeIcon`, `layout1ID`/`layout2ID`, `autoSwitch`):

```markdown
| Ключ (префикс com.ruswitcher.) | Значения | Дефолт | Смысл |
|---|---|---|---|
| triggerKey | option \| command \| control \| shift \| capsLock | option | триггер конвертации |
| triggerRightOnly | true/false | false | только правая клавиша пары |
| triggerDoubleTap | true/false | false | двойной тап вместо одиночного |
| autoSwitch | true/false | true | мастер-выключатель (= пункт меню) |
| debugLog | true/false | false | лог в ~/Library/Logs/RuSwitcher/ |
| launchAtLogin | true/false | false | автозапуск при логине |
| keySound | true/false | false | звук при конвертации |
| monochromeIcon | true/false | false | монохромная иконка меню-бара |
| layout1ID / layout2ID | id источников ввода | авто | пара раскладок вручную |

Пример: `defaults write com.ruswitcher.app com.ruswitcher.triggerKey -string command` (+ перезапуск приложения)
```

Дефолты в таблице сверить с кодом SettingsManager (get-ветки свойств) и поправить по факту.

- [ ] **Step 4: Финальные инварианты**

Run: `grep -rn "URLSession\|NSPasteboard" Sources/ | wc -l && swift build 2>&1 | tail -3 && wc -l Sources/RuSwitcher/*.swift | tail -1`
Expected: `0`, `Build complete!`, суммарно ~2500-3000 строк (было 5796 c Localization).

- [ ] **Step 5:**

```bash
git add -A && git commit -m "lite: убрать поставку DMG/brew/статистику, README для lite

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push origin lite
```

---

### Task 9: Сборка .app и ручной смоук-тест

**Files:**
- Create: `/Users/ruzal/sandbox/test/human_task_ruswitcher_lite_install.md` (вне репозитория!)

- [ ] **Step 1: Собрать приложение**

Run: `./build_app.sh 2>&1 | tail -5`
Expected: сборка успешна, в корне появился `RuSwitcher.app` (точное имя/путь покажет скрипт).

- [ ] **Step 2: Создать human_task с чекбоксами** (файл в `/Users/ruzal/sandbox/test/`, НЕ в репо форка) и открыть `mdmini /Users/ruzal/sandbox/test/human_task_ruswitcher_lite_install.md`. Содержимое:

```markdown
# Установка и смоук-тест RuSwitcher lite

## Установка
- [ ] Скопировать RuSwitcher.app в /Applications (из /Users/ruzal/sandbox/test/RuSwitcher/)
- [ ] Запустить; при жалобе Gatekeeper: System Settings → Privacy & Security → Open Anyway
- [ ] Выдать права: System Settings → Privacy & Security → Accessibility → + RuSwitcher
- [ ] Выдать права: System Settings → Privacy & Security → Input Monitoring → + RuSwitcher
- [ ] Перезапустить приложение после выдачи прав

## Смоук-тест (в Chrome-адресной строке, Slack, iTerm2, VS Code, Spotlight)
- [ ] Набрать `ghbdtn`, тап Option → стало `привет`, раскладка переключилась на RU (индикатор в меню-баре)
- [ ] Повторный тап Option → обратно `ghbdtn`, раскладка EN
- [ ] Набрать слово, кликнуть мышью в другое место, тап Option → ничего не произошло, текст цел
- [ ] `defaults write com.ruswitcher.app com.ruswitcher.triggerKey -string command` + перезапуск → работает по Cmd-тапу
- [ ] Вернуть: `defaults delete com.ruswitcher.app com.ruswitcher.triggerKey` + перезапуск
```

- [ ] **Step 3: Дождаться результатов смоук-теста от пользователя.** Если всё зелёное — работа завершена; проблемные приложения фиксировать и чинить отдельными задачами.
