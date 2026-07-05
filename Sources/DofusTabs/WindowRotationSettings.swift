import Foundation

/// Persiste qué personajes se excluyen a mano de la rotación de hotkeys
/// (ciclo Cmd+1 y atajos directos Cmd+2...9) — típicamente mules o cuentas
/// aparcadas que no interesa que interrumpan el ciclo.
final class WindowRotationSettings {
    private let defaultsKey = "com.martiferretc.dofustabs.excludedCharacters"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var excludedNames: Set<String> {
        get { Set(defaults.stringArray(forKey: defaultsKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: defaultsKey) }
    }

    func isExcluded(_ name: String) -> Bool {
        excludedNames.contains(name)
    }

    func setExcluded(_ excluded: Bool, for name: String) {
        var current = excludedNames
        if excluded {
            current.insert(name)
        } else {
            current.remove(name)
        }
        excludedNames = current
    }
}
