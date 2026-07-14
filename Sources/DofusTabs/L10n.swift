import Foundation

/// Centraliza el acceso a las cadenas localizadas (`Resources/{en,es,fr}.lproj/Localizable.strings`).
/// Usa `Bundle.module`, el bundle de recursos que genera SwiftPM, no `Bundle.main`.
enum L10n {
    static var menuNoDofusDetected: String { string("menu.no_dofus_detected") }
    static var menuExcludedSuffix: String { string("menu.excluded_suffix") }
    static var menuArrangeWindows: String { string("menu.arrange_windows") }
    static var menuSettings: String { string("menu.settings") }
    static var menuRefresh: String { string("menu.refresh") }
    static var menuQuit: String { string("menu.quit") }
    static var menuFloatingPanel: String { string("menu.floating_panel") }

    static var settingsWindowTitle: String { string("settings.window_title") }
    static var settingsCharactersDetected: String { string("settings.characters_detected") }
    static var settingsNoWindows: String { string("settings.no_windows") }
    static var settingsLaunchAtLogin: String { string("settings.launch_at_login") }
    static var settingsArrangeNow: String { string("settings.arrange_now") }
    static var settingsResetHotkeys: String { string("settings.reset_hotkeys") }
    static var settingsFooterNote: String { string("settings.footer_note") }
    static var settingsGlobalHotkeys: String { string("settings.global_hotkeys") }
    static var settingsCycleHotkeyLabel: String { string("settings.cycle_hotkey_label") }
    static var settingsArrangeHotkeyLabel: String { string("settings.arrange_hotkey_label") }
    static var settingsExcludedFromRotation: String { string("settings.excluded_from_rotation") }

    static var hotkeyRecordingPlaceholder: String { string("hotkey.recording_placeholder") }

    static var settingsLanguageSection: String { string("settings.language_section") }
    static var settingsLanguageSystem: String { string("settings.language_system") }
    static var languageRestartTitle: String { string("language.restart_title") }
    static var languageRestartMessage: String { string("language.restart_message") }
    static var languageRestartNow: String { string("language.restart_now") }
    static var languageRestartLater: String { string("language.restart_later") }

    static func menuUpdateAvailable(version: String) -> String {
        String(format: string("menu.update_available"), version)
    }
    static var menuCheckForUpdates: String { string("menu.check_for_updates") }
    static var updateAvailableTitle: String { string("update.available_title") }
    static func updateAvailableMessage(version: String) -> String {
        String(format: string("update.available_message"), version)
    }
    static var updateDownloadButton: String { string("update.download_button") }
    static var updateLaterButton: String { string("update.later_button") }
    static var updateUpToDateTitle: String { string("update.up_to_date_title") }
    static var updateUpToDateMessage: String { string("update.up_to_date_message") }
    static var updateOkButton: String { string("update.ok_button") }

    private static func string(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    /// Cuando hay un idioma forzado desde Ajustes, carga directamente el
    /// `.lproj` correspondiente en vez de fiarse de la resolución automática
    /// de `Bundle.module` (que lee `AppleLanguages` a través de
    /// `kCFPreferencesCurrentApplication`, algo ligado al `bundleIdentifier`
    /// del proceso — bajo `swift run`, sin bundle real, es `nil` y esa
    /// resolución automática cae directo al `defaultLocalization` del
    /// paquete en vez de respetar la preferencia guardada). Cargar el
    /// `.lproj` a mano evita depender de ese mecanismo por completo y
    /// funciona igual en `swift run` que en el `.app` empaquetado.
    private static var localizedBundle: Bundle {
        let selection = LanguagePreferenceStore().current
        guard selection != .system,
              let path = Bundle.module.path(forResource: selection.rawValue, ofType: "lproj"),
              let overrideBundle = Bundle(path: path) else {
            return Bundle.module
        }
        return overrideBundle
    }
}
