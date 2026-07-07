import CoreGraphics

/// Конвертация текста между раскладками
@MainActor
final class TextConverter {
    private var isConverting = false
    /// Очередь для инжекта нажатий буферного движка — чтобы usleep не блокировал
    /// main-поток, на котором висит event tap (иначе тап голодает → лаги/потери нажатий).
    nonisolated private let injectQueue = DispatchQueue(label: "com.ruswitcher.inject", qos: .userInteractive)

    // Состояние движка перепечатки (буфер нажатий → юникод-вставка)
    private var lastOriginal = ""
    private var lastConverted = ""

    /// Создаёт CGEventSource с маркером, чтобы KeyboardMonitor игнорировал наши события
    nonisolated private func makeSource() -> CGEventSource? {
        let source = CGEventSource(stateID: .hidSystemState)
        source?.userData = kRuSwitcherEventMarker
        return source
    }

    // MARK: - Public API

    /// Движок перепечатки: стираем набранное и впечатываем конвертированное через
    /// юникод-вставку — без буфера обмена и без выделения (работает в Atom/Electron).
    /// Тихо ничего не делает, если буфера нет (текст выделен мышью) или
    /// раскладки не определились — clipboard-движок в lite-версии убран.
    func convert(wordKeys: [TypedKey], prevWordKeys: [TypedKey], boundaryCount: Int) -> Bool {
        let keys: [TypedKey]
        let trailingSpaces: Int
        if !wordKeys.isEmpty {
            keys = wordKeys; trailingSpaces = 0
        } else if !prevWordKeys.isEmpty && boundaryCount > 0 {
            keys = prevWordKeys; trailingSpaces = boundaryCount
        } else {
            rslog("buffer convert: no typed buffer — skip (clipboard engine removed in lite)")
            return false
        }

        guard let pair = DynamicKeyMapping.convertKeys(keys) else {
            rslog("buffer convert: layouts not resolved — skip (clipboard engine removed in lite)")
            return false
        }

        guard !isConverting else { return false }
        isConverting = true

        let spaces = String(repeating: " ", count: trailingSpaces)
        let bsCount = keys.count + trailingSpaces
        let insert = pair.converted + spaces
        lastOriginal = pair.original + spaces
        lastConverted = pair.converted + spaces
        rslog("buffer convert: \(keys.count) keys (+\(trailingSpaces) sp)")

        // Инжект — вне main, чтобы usleep не голодал event tap.
        injectQueue.async { [weak self] in
            guard let self else { return }
            self.backspace(bsCount)
            usleep(20_000)
            self.insertText(insert)
            Task { @MainActor in self.isConverting = false }
        }
        return true
    }

    /// Повторная конвертация (второй триггер) — свап lastOriginal/lastConverted и
    /// повторный инжект через буферный движок.
    func reconvert() -> Bool {
        guard !isConverting else { return false }
        guard !lastConverted.isEmpty else { return false }
        isConverting = true
        rslog("buffer reconvert")
        let bsCount = lastConverted.count
        let insert = lastOriginal
        let tmp = lastOriginal; lastOriginal = lastConverted; lastConverted = tmp
        injectQueue.async { [weak self] in
            guard let self else { return }
            self.backspace(bsCount)
            usleep(20_000)
            self.insertText(insert)
            Task { @MainActor in self.isConverting = false }
        }
        return true
    }

    // MARK: - Private

    /// Стирает n символов (Backspace × n) — для движка перепечатки.
    nonisolated private func backspace(_ n: Int) {
        for _ in 0..<n {
            simKey(keyCode: KC.backspace, flags: [])
            usleep(3_000)
        }
    }

    /// Впечатывает строку напрямую (юникод-вставка), без буфера обмена.
    nonisolated private func insertText(_ text: String) {
        guard !text.isEmpty, let source = makeSource() else { return }
        let utf16 = Array(text.utf16)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }
        utf16.withUnsafeBufferPointer { buf in
            down.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: buf.baseAddress)
            up.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: buf.baseAddress)
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    /// Симулирует нажатие клавиши с маркером (чтобы наш monitor игнорировал)
    nonisolated private func simKey(keyCode: UInt16, flags: CGEventFlags) {
        guard let source = makeSource() else { return }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
