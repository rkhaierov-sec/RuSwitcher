import Foundation

/// Локализация интерфейса на 16 языков (вкомпилированные строки)
enum L10n {
    // MARK: - Меню
    static var menuAutoSwitch: String { s("menu.autoSwitch") }
    static var menuCheckPermissions: String { s("menu.checkPermissions") }
    static var menuQuit: String { s("menu.quit") }

    // MARK: - Визард разрешений
    static var wizardPermissionsResetTitle: String { s("wizard.permissionsReset.title") }
    static var wizardPermissionsResetText: String { s("wizard.permissionsReset.text") }
    static var permissionsOkTitle: String { s("wizard.permissionsOk.title") }
    static var permissionsOkText: String { s("wizard.permissionsOk.text") }

    // MARK: - Private

    nonisolated(unsafe) private static var currentLang: String = detectLanguage()

    static let supportedLanguages = Set(["en", "ru", "de", "fr", "es", "pt", "zh", "ja", "ko", "uk", "pl", "be", "el", "bg", "hy", "ka"])

    private static func detectLanguage() -> String {
        // Проверяем принудительный язык из настроек
        let forced = UserDefaults.standard.string(forKey: "com.ruswitcher.interfaceLanguage") ?? ""
        if !forced.isEmpty && supportedLanguages.contains(forced) {
            return forced
        }
        // Авто-определение по системе
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = String(preferred.prefix(2))
        return supportedLanguages.contains(code) ? code : "en"
    }

    /// Перезагрузить язык (вызывается при смене в настройках)
    static func reloadLanguage() {
        currentLang = detectLanguage()
    }

    private static func s(_ key: String) -> String {
        strings[currentLang]?[key] ?? strings["en"]![key] ?? key
    }

    // MARK: - Все строки

    private static let strings: [String: [String: String]] = [
        // ========== ENGLISH ==========
        "en": [
            "menu.autoSwitch": "Enable RuSwitcher",
            "menu.checkPermissions": "Check Permissions…",
            "menu.quit": "Quit",

            "wizard.permissionsReset.title": "Permissions Reset After Update",
            "wizard.permissionsReset.text": "macOS has reset permissions because the app was updated.\n\nRuSwitcher will remove old entries and request permissions again.\nYou just need to flip the toggles.",
            "wizard.permissionsOk.title": "All Permissions Granted",
            "wizard.permissionsOk.text": "Accessibility and Input Monitoring are enabled. RuSwitcher is working.",

        ],

        // ========== РУССКИЙ ==========
        "ru": [
            "menu.autoSwitch": "Включить RuSwitcher",
            "menu.checkPermissions": "Проверить разрешения…",
            "menu.quit": "Выход",

            "wizard.permissionsReset.title": "Разрешения сброшены после обновления",
            "wizard.permissionsReset.text": "macOS сбросил разрешения из-за обновления программы.\n\nRuSwitcher удалит старые записи и запросит разрешения заново.\nВам нужно только включить тумблеры.",
            "wizard.permissionsOk.title": "Все разрешения на месте",
            "wizard.permissionsOk.text": "«Универсальный доступ» и «Мониторинг ввода» включены. RuSwitcher работает.",

        ],

        // ========== DEUTSCH ==========
        "de": [
            "menu.autoSwitch": "RuSwitcher aktivieren",
            "menu.checkPermissions": "Berechtigungen prüfen…",
            "menu.quit": "Beenden",
            "wizard.permissionsReset.title": "Berechtigungen nach Update zurückgesetzt",
            "wizard.permissionsReset.text": "macOS hat die Berechtigungen nach dem App-Update zurückgesetzt.\n\nRuSwitcher entfernt alte Einträge und fordert Berechtigungen erneut an.\nSie müssen nur die Schalter umlegen.",
            "wizard.permissionsOk.title": "Alle Berechtigungen erteilt",
            "wizard.permissionsOk.text": "Bedienungshilfen und Eingabeüberwachung sind aktiviert. RuSwitcher funktioniert.",
        ],

        // ========== FRANÇAIS ==========
        "fr": [
            "menu.autoSwitch": "Activer RuSwitcher",
            "menu.checkPermissions": "Vérifier les autorisations…",
            "menu.quit": "Quitter",
            "wizard.permissionsReset.title": "Autorisations réinitialisées après mise à jour",
            "wizard.permissionsReset.text": "macOS a réinitialisé les autorisations suite à la mise à jour.\n\nRuSwitcher supprimera les anciennes entrées et redemandera les autorisations.\nVous n'avez qu'à activer les boutons.",
            "wizard.permissionsOk.title": "Toutes les autorisations sont accordées",
            "wizard.permissionsOk.text": "L’Accessibilité et la Surveillance de la saisie sont activées. RuSwitcher fonctionne.",
        ],

        // ========== ESPAÑOL ==========
        "es": [
            "menu.autoSwitch": "Activar RuSwitcher",
            "menu.checkPermissions": "Verificar permisos…",
            "menu.quit": "Salir",
            "wizard.permissionsReset.title": "Permisos restablecidos tras actualización",
            "wizard.permissionsReset.text": "macOS ha restablecido los permisos tras la actualización.\n\nRuSwitcher eliminará las entradas antiguas y solicitará permisos de nuevo.\nSolo necesita activar los interruptores.",
            "wizard.permissionsOk.title": "Todos los permisos concedidos",
            "wizard.permissionsOk.text": "Accesibilidad y Monitorización de entrada están activados. RuSwitcher funciona.",
        ],

        // ========== PORTUGUÊS ==========
        "pt": [
            "menu.autoSwitch": "Ativar RuSwitcher",
            "menu.checkPermissions": "Verificar permissões…",
            "menu.quit": "Sair",
            "wizard.permissionsReset.title": "Permissões redefinidas após atualização",
            "wizard.permissionsReset.text": "O macOS redefiniu as permissões porque o app foi atualizado.\n\nO RuSwitcher removerá as entradas antigas e solicitará as permissões novamente.\nVocê só precisa ativar os botões.",
            "wizard.permissionsOk.title": "Todas as permissões concedidas",
            "wizard.permissionsOk.text": "Acessibilidade e Monitoramento de entrada estão ativados. O RuSwitcher está funcionando.",
        ],

        // ========== 中文 ==========
        "zh": [
            "menu.autoSwitch": "启用 RuSwitcher",
            "menu.checkPermissions": "检查权限…",
            "menu.quit": "退出",
            "wizard.permissionsReset.title": "更新后权限已重置",
            "wizard.permissionsReset.text": "由于 App 已更新，macOS 重置了权限。\n\nRuSwitcher 将移除旧条目并重新请求权限。\n你只需重新打开开关即可。",
            "wizard.permissionsOk.title": "已授予所有权限",
            "wizard.permissionsOk.text": "辅助功能和输入监控已启用。RuSwitcher 正常运行。",
        ],

        // ========== 日本語 ==========
        "ja": [
            "menu.autoSwitch": "RuSwitcher を有効にする",
            "menu.checkPermissions": "権限を確認…",
            "menu.quit": "終了",
            "wizard.permissionsReset.title": "アップデート後に権限がリセットされました",
            "wizard.permissionsReset.text": "Appがアップデートされたため、macOSが権限をリセットしました。\n\nRuSwitcherは古いエントリを削除し、権限を再度リクエストします。\nスイッチを入れ直すだけです。",
            "wizard.permissionsOk.title": "すべての権限が許可されています",
            "wizard.permissionsOk.text": "アクセシビリティと入力監視が有効です。RuSwitcherは動作しています。",
        ],

        // ========== 한국어 ==========
        "ko": [
            "menu.autoSwitch": "RuSwitcher 사용",
            "menu.checkPermissions": "권한 확인…",
            "menu.quit": "종료",
            "wizard.permissionsReset.title": "업데이트 후 권한이 재설정됨",
            "wizard.permissionsReset.text": "앱이 업데이트되어 macOS가 권한을 재설정했습니다.\n\nRuSwitcher가 이전 항목을 제거하고 권한을 다시 요청합니다.\n스위치만 다시 켜면 됩니다.",
            "wizard.permissionsOk.title": "모든 권한이 허용됨",
            "wizard.permissionsOk.text": "손쉬운 사용과 입력 모니터링이 활성화되었습니다. RuSwitcher가 작동 중입니다.",
        ],

        // ========== УКРАЇНСЬКА ==========
        "uk": [
            "menu.autoSwitch": "Увімкнути RuSwitcher",
            "menu.checkPermissions": "Перевірити дозволи…",
            "menu.quit": "Вихід",

            "wizard.permissionsReset.title": "Дозволи скинуті після оновлення",
            "wizard.permissionsReset.text": "macOS скинув дозволи через оновлення програми.\n\nRuSwitcher видалить старі записи і запросить дозволи знову.\nВам потрібно лише увімкнути перемикачі.",

            "wizard.permissionsOk.title": "Усі дозволи надано",
            "wizard.permissionsOk.text": "«Доступність» та «Моніторинг вводу» увімкнено. RuSwitcher працює.",
        ],

        // ========== БЕЛАРУСКАЯ ==========
        "be": [
            "menu.autoSwitch": "Уключыць RuSwitcher",
            "menu.checkPermissions": "Праверыць дазволы…",
            "menu.quit": "Выхад",

            "wizard.permissionsReset.title": "Дазволы скінуты пасля абнаўлення",
            "wizard.permissionsReset.text": "macOS скінуў дазволы з-за абнаўлення праграмы.\n\nRuSwitcher выдаліць старыя запісы і запытае дазволы нанова.\nВам трэба толькі ўключыць пераключальнікі.",

            "wizard.permissionsOk.title": "Усе дазволы дадзены",
            "wizard.permissionsOk.text": "«Спецыяльныя магчымасці» і «Маніторынг уводу» уключаны. RuSwitcher працуе.",
        ],

        // ========== POLSKI ==========
        "pl": [
            "menu.autoSwitch": "Włącz RuSwitcher",
            "menu.checkPermissions": "Sprawdź uprawnienia…",
            "menu.quit": "Zakończ",
            "wizard.permissionsReset.title": "Uprawnienia zresetowane po aktualizacji",
            "wizard.permissionsReset.text": "macOS zresetował uprawnienia, ponieważ aplikacja została zaktualizowana.\n\nRuSwitcher usunie stare wpisy i ponownie poprosi o uprawnienia.\nWystarczy przełączyć przełączniki.",
            "wizard.permissionsOk.title": "Wszystkie uprawnienia przyznane",
            "wizard.permissionsOk.text": "Dostępność i Monitorowanie wejścia są włączone. RuSwitcher działa.",
        ],
        "el": [
            "menu.autoSwitch": "Ενεργοποίηση RuSwitcher",
            "menu.checkPermissions": "Έλεγχος δικαιωμάτων…",
            "menu.quit": "Έξοδος",
            "wizard.permissionsReset.title": "Τα δικαιώματα επαναφέρθηκαν μετά την ενημέρωση",
            "wizard.permissionsReset.text": "Το macOS επανέφερε τα δικαιώματα επειδή η εφαρμογή ενημερώθηκε.\n\nΤο RuSwitcher θα αφαιρέσει τις παλιές καταχωρήσεις και θα ζητήσει ξανά δικαιώματα.\nΑρκεί να ενεργοποιήσετε τους διακόπτες.",
            "wizard.permissionsOk.title": "Όλα τα δικαιώματα χορηγήθηκαν",
            "wizard.permissionsOk.text": "Η Προσβασιμότητα και η Παρακολούθηση εισόδου είναι ενεργές. Το RuSwitcher λειτουργεί.",
        ],
        "bg": [
            "menu.autoSwitch": "Включи RuSwitcher",
            "menu.checkPermissions": "Проверка на разрешения…",
            "menu.quit": "Изход",
            "wizard.permissionsReset.title": "Разрешенията са нулирани след актуализация",
            "wizard.permissionsReset.text": "macOS нулира разрешенията, защото приложението беше актуализирано.\n\nRuSwitcher ще премахне старите записи и ще поиска разрешения отново.\nТрябва само да включите превключвателите.",
            "wizard.permissionsOk.title": "Всички разрешения са дадени",
            "wizard.permissionsOk.text": "Достъпността и Наблюдението на въвеждането са включени. RuSwitcher работи.",
        ],
        "hy": [
            "menu.autoSwitch": "Միացնել RuSwitcher",
            "menu.checkPermissions": "Ստուգել թույլտվությունները…",
            "menu.quit": "Ելք",
            "wizard.permissionsReset.title": "Թույլտվությունները զրոյացվել են թարմացումից հետո",
            "wizard.permissionsReset.text": "macOS-ը զրոյացրել է թույլտվությունները, քանի որ ծրագիրը թարմացվել է.\n\nRuSwitcher-ը կհեռացնի հին գրառումները և կրկին կպահանջի թույլտվություններ.\nՊարզապես միացրեք անջատիչները.",
            "wizard.permissionsOk.title": "Բոլոր թույլտվությունները տրված են",
            "wizard.permissionsOk.text": "Մատչելիությունը և Ներմուծման հսկողությունը միացված են: RuSwitcher-ն աշխատում է.",
        ],
        "ka": [
            "menu.autoSwitch": "RuSwitcher-ის ჩართვა",
            "menu.checkPermissions": "ნებართვების შემოწმება…",
            "menu.quit": "გასვლა",
            "wizard.permissionsReset.title": "ნებართვები განულდა განახლების შემდეგ",
            "wizard.permissionsReset.text": "macOS-მა განულა ნებართვები, რადგან აპი განახლდა.\n\nRuSwitcher წაშლის ძველ ჩანაწერებს და თავიდან მოითხოვს ნებართვებს.\nუბრალოდ ჩართეთ გადამრთველები.",
            "wizard.permissionsOk.title": "ყველა ნებართვა მინიჭებულია",
            "wizard.permissionsOk.text": "წვდომადობა და შეყვანის მონიტორინგი ჩართულია. RuSwitcher მუშაობს.",
        ],
    ]
}
