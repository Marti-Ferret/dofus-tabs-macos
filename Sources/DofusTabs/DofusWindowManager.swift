import AppKit
import ApplicationServices
import CoreGraphics

struct DofusWindow {
    let pid: pid_t
    let axElement: AXUIElement
    let characterName: String
    let rawTitle: String
}

/// Detecta y controla las ventanas de Dofus vía la Accessibility API.
///
/// Sustituye al enfoque de AppleScript/`System Events` usado por el único
/// proyecto de Mac existente (rolljee/Organizer-dofus): AXUIElement da
/// foco casi instantáneo y no depende de spawnear `osascript`.
final class DofusWindowManager {
    private(set) var windows: [DofusWindow] = []
    private var cursor = 0
    private let orderStore = CharacterOrderStore()
    private let rotationSettings = WindowRotationSettings()

    /// Ventanas que sí participan en el ciclo Cmd+1 y en los atajos directos
    /// Cmd+2...9 — excluye las marcadas manualmente como mule/aparcadas.
    var activeWindows: [DofusWindow] {
        windows.filter { !rotationSettings.isExcluded($0.characterName) }
    }

    /// Vuelve a escanear los procesos de Dofus en ejecución y sus ventanas.
    func refresh() {
        var result: [DofusWindow] = []

        let dofusApps = NSWorkspace.shared.runningApplications.filter {
            $0.localizedName?.localizedCaseInsensitiveContains("Dofus") == true
        }

        for app in dofusApps {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var value: CFTypeRef?
            let status = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)

            guard status == .success, let windowRefs = value as? [AXUIElement] else { continue }

            for windowRef in windowRefs {
                var titleValue: CFTypeRef?
                AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute as CFString, &titleValue)
                let title = (titleValue as? String) ?? app.localizedName ?? "Dofus"

                result.append(
                    DofusWindow(
                        pid: app.processIdentifier,
                        axElement: windowRef,
                        characterName: Self.parseCharacterName(from: title),
                        rawTitle: title
                    )
                )
            }
        }

        // Orden estable entre refrescos/reinicios, para que los atajos
        // directos (Cmd+1...Cmd+9) siempre apunten al mismo personaje.
        let orderedNames = orderStore.sort(result.map { $0.characterName })
        let rank = Dictionary(orderedNames.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        result.sort { (rank[$0.characterName] ?? .max) < (rank[$1.characterName] ?? .max) }

        windows = result
    }

    /// Formato observado en la versión Windows (Unity): "Nombre - Clase - Version - Release".
    /// TODO: validar si Dofus Unity/Retro en macOS usa el mismo formato de título.
    static func parseCharacterName(from title: String) -> String {
        if let range = title.range(of: " - ") {
            return String(title[title.startIndex..<range.lowerBound])
        }
        return title
    }

    func focus(_ window: DofusWindow) {
        AXUIElementSetAttributeValue(window.axElement, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window.axElement, kAXRaiseAction as CFString)

        if let runningApp = NSRunningApplication(processIdentifier: window.pid) {
            runningApp.activate(options: [.activateIgnoringOtherApps])
        }

        if let index = activeWindows.firstIndex(where: { $0.characterName == window.characterName }) {
            cursor = index
        }
    }

    func focusNextWindow() {
        let active = activeWindows
        guard !active.isEmpty else { return }
        cursor = (cursor + 1) % active.count
        focus(active[cursor])
    }

    func isExcluded(_ window: DofusWindow) -> Bool {
        rotationSettings.isExcluded(window.characterName)
    }

    func setExcluded(_ excluded: Bool, for window: DofusWindow) {
        rotationSettings.setExcluded(excluded, for: window.characterName)
    }

    /// Aplica un orden explícito (tras un reorder manual desde Ajustes) y
    /// vuelve a escanear para que `windows` refleje el nuevo orden ya.
    func setOrder(_ names: [String]) {
        orderStore.setOrder(names)
        refresh()
    }

}
