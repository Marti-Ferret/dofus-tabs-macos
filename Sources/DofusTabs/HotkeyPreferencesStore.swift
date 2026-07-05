import Foundation

/// Persiste qué tecla+modificadores usa cada atajo: el ciclo, el de
/// organizar ventanas, y cada uno de los hasta 9 atajos directos por
/// posición (posición = puesto entre las ventanas activas, no personaje
/// concreto — igual que el número ya funcionaba antes de ser personalizable).
final class HotkeyPreferencesStore {
    private let defaults: UserDefaults
    private let cycleKey = "com.martiferretc.dofustabs.hotkey.cycle"
    private let arrangeKey = "com.martiferretc.dofustabs.hotkey.arrange"
    private let directKeyPrefix = "com.martiferretc.dofustabs.hotkey.direct."
    private let maxDirectSlots = 9

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var cycleBinding: HotkeyBinding {
        get { decode(cycleKey) ?? .defaultCycle }
        set { encode(newValue, forKey: cycleKey) }
    }

    var arrangeBinding: HotkeyBinding {
        get { decode(arrangeKey) ?? .defaultArrange }
        set { encode(newValue, forKey: arrangeKey) }
    }

    func directBinding(at index: Int) -> HotkeyBinding {
        decode(directKeyPrefix + "\(index)") ?? .defaultDirect(at: index)
    }

    func setDirectBinding(_ binding: HotkeyBinding, at index: Int) {
        encode(binding, forKey: directKeyPrefix + "\(index)")
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: cycleKey)
        defaults.removeObject(forKey: arrangeKey)
        for index in 0..<maxDirectSlots {
            defaults.removeObject(forKey: directKeyPrefix + "\(index)")
        }
    }

    private func decode(_ key: String) -> HotkeyBinding? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HotkeyBinding.self, from: data)
    }

    private func encode(_ value: HotkeyBinding, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
