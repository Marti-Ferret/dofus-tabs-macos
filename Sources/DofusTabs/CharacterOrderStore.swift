import Foundation

/// Persiste el orden en que se ha visto cada personaje para que los atajos
/// directos (Cmd+1...Cmd+9) apunten siempre al mismo personaje entre sesiones,
/// aunque el orden en que macOS devuelve los procesos/ventanas no sea estable.
final class CharacterOrderStore {
    private let defaultsKey = "com.martiferretc.dofustabs.characterOrder"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Devuelve `names` ordenados según el histórico guardado. Los nombres
    /// nuevos se añaden al final (en el orden en que llegan) y se persisten
    /// para la próxima vez.
    func sort(_ names: [String]) -> [String] {
        var order = defaults.stringArray(forKey: defaultsKey) ?? []
        let known = Set(order)
        let newcomers = names.filter { !known.contains($0) }

        if !newcomers.isEmpty {
            order.append(contentsOf: newcomers)
            defaults.set(order, forKey: defaultsKey)
        }

        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        return names.sorted { (rank[$0] ?? .max) < (rank[$1] ?? .max) }
    }

    /// Sustituye el orden guardado por uno explícito (usado tras un reorder manual
    /// desde Ajustes). Los personajes que no estén en `names` se pierden del
    /// histórico; si vuelven a aparecer más adelante, se añadirán de nuevo al final.
    func setOrder(_ names: [String]) {
        defaults.set(names, forKey: defaultsKey)
    }
}
