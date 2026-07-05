import AppKit

/// Los nombres de idioma se muestran siempre en su propio idioma (convención
/// estándar en selectores de idioma), no traducidos al idioma actual de la UI.
enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case system
    case en
    case es
    case fr

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .system: return L10n.settingsLanguageSystem
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        }
    }
}

/// Fuerza el idioma de la app sobreescribiendo `AppleLanguages` en las
/// preferencias propias de la app — el mismo mecanismo que `defaults write
/// <bundle-id> AppleLanguages -array fr` o el flag `-AppleLanguages` por
/// línea de comandos. Aplica a todos los bundles del proceso, incluido
/// `Bundle.module`, pero requiere reiniciar la app para que toda la UI ya
/// construida (menú, Ajustes) se reconstruya en el idioma nuevo.
final class LanguagePreferenceStore {
    private let selectionKey = "com.martiferretc.dofustabs.languageOverride"
    private let appleLanguagesKey = "AppleLanguages"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var current: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: selectionKey) ?? "system") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: selectionKey) }
    }

    func apply(_ language: AppLanguage) {
        current = language
        switch language {
        case .system:
            defaults.removeObject(forKey: appleLanguagesKey)
        default:
            defaults.set([language.rawValue], forKey: appleLanguagesKey)
        }
    }

    /// Relanza la app (funciona tanto para el `.app` empaquetado como para
    /// `swift run` en desarrollo) y cierra el proceso actual.
    func relaunch() {
        let task = Process()
        if Bundle.main.bundlePath.hasSuffix(".app") {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = [Bundle.main.bundlePath]
        } else {
            task.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        }
        try? task.run()
        NSApplication.shared.terminate(nil)
    }
}
