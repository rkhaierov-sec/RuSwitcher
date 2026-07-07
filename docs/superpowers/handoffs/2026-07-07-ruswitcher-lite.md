# Handoff: RuSwitcher Lite — исполнение плана

## Цель

Урезать форк RuSwitcher (ветка `lite`) до личной сборки: тап по триггеру → конвертация
последнего слова + переключение системной раскладки, откат повторным тапом; ноль сети,
ноль clipboard, без GUI-настроек.

## Статус

- Форк создан: https://github.com/rkhaierov-sec/RuSwitcher, ветка `lite`
  (локально: `/Users/ruzal/sandbox/test/RuSwitcher`). `main` — зеркало апстрима, не трогать.
- Спека одобрена пользователем и закоммичена: `docs/superpowers/specs/2026-07-07-ruswitcher-lite-design.md` (bb13346).
- План написан, само-ревью пройдено, закоммичен: `docs/superpowers/plans/2026-07-07-ruswitcher-lite.md` (cd1be50).
- Код НЕ тронут — исполнение плана не начиналось. Сборка проверялась только чтением
  (`swift build` ещё ни разу не запускался — первая задача плана это проверит).

## Что дальше

Исполнить все 9 задач плана `docs/superpowers/plans/2026-07-07-ruswitcher-lite.md`
через **superpowers:subagent-driven-development** (выбор пользователя: свежий субагент
на задачу, ревью между задачами). Порядок — по плану, задачи 1→9, после каждой —
зелёный `swift build` + коммит.

## Ключевые файлы

- `docs/superpowers/plans/2026-07-07-ruswitcher-lite.md` — план: 9 задач с точными шагами,
  кодом и grep-проверками. Исполнять его, а не пересочинять.
- `docs/superpowers/specs/2026-07-07-ruswitcher-lite-design.md` — спека: требования,
  таблица ключей `defaults write`, риски.
- `Sources/RuSwitcher/AppDelegate.swift` (783 строки) — больше всего правок (задачи 1–5).
- `Sources/RuSwitcher/TextConverter.swift` — задача 6 (вырезать clipboard-движок).
- Ядро НЕ трогать: KeyboardMonitor, DynamicKeyMapping, KeyMapping, LayoutSwitcher, KeyCodes.

## Решения и контекст

- Одноразовый отрыв от апстрима: файлы удаляем смело, mergeability не поддерживаем.
- GUI настроек выпиливаем, но настраиваемость остаётся через `defaults write com.ruswitcher.app ...`
  (таблица значений — в спеке и будет в README, задача 8). Это явная просьба пользователя:
  «сохрани варианты выбора».
- Ключи `keySound`/`monochromeIcon` оставить в SettingsManager без пунктов меню — их
  читают KeyboardMonitor (ядро) и отрисовка иконки.
- Требование пользователя №1: после конвертации раскладка ДОЛЖНА переключаться на целевую
  (у flipio с этим был баг) — `LayoutSwitcher.switchToOpposite()` в колбэках сохранён,
  отдельный пункт смоук-теста.
- Откат повторным тапом — буферная ветка `reconvert()`, от clipboard не зависит, сохраняется.
- В апстримовском `.gitignore` был `docs/` (автор держит спеки вне публичного репо) — мы
  правило убрали и коммитим доки в форк; пользователь в курсе.

## Грабли

- `git add docs/...` сначала упал: `docs/` был в `.gitignore` апстрима — уже починено (bb13346).
- Не редактировать KeyboardMonitor при удалении колбэков `onUserInput`/`onWordBoundary` —
  это опциональные свойства, неприсвоенными быть могут; править только AppDelegate.
- `lastFlagShown` в AppDelegate — про иконку меню-бара, НЕ про CaretIndicator; при задаче 3
  не удалять.
- human_task-файл (задача 9) класть в `/Users/ruzal/sandbox/test/`, НЕ в репо форка.

## Первый шаг

В `/Users/ruzal/sandbox/test/RuSwitcher` (ветка `lite`): вызвать скилл
`superpowers:subagent-driven-development` с планом
`docs/superpowers/plans/2026-07-07-ruswitcher-lite.md` и запустить задачу 1
(выпилить UpdateChecker).
