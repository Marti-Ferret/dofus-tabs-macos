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
        let rank = Dictionary(uniqueKeysWithValues: orderedNames.enumerated().map { ($1, $0) })
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

    /// Captura una miniatura de la ventana (requiere permiso de Grabación de pantalla).
    /// Se calcula bajo demanda, no en cada refresh periódico, para no cargar CPU/GPU
    /// haciendo capturas de pantalla cada pocos segundos en segundo plano.
    func thumbnail(for window: DofusWindow, maxDimension: CGFloat = 34) -> NSImage? {
        guard let windowID = cgWindowID(for: window.axElement, pid: window.pid) else { return nil }

        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        ), cgImage.width > 0, cgImage.height > 0 else {
            return nil
        }

        let originalSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale = maxDimension / max(originalSize.width, originalSize.height)
        let thumbnailSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)

        return NSImage(cgImage: cgImage, size: thumbnailSize).roundedCorners(radius: thumbnailSize.width * 0.2)
    }

    /// No existe una API pública que vaya directamente de AXUIElement a CGWindowID,
    /// así que se emparejan por PID + posición/tamaño de ventana (con margen de error).
    private func cgWindowID(for axWindow: AXUIElement, pid: pid_t) -> CGWindowID? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef)

        var position = CGPoint.zero
        var size = CGSize.zero
        if let positionRef, CFGetTypeID(positionRef) == AXValueGetTypeID() {
            AXValueGetValue((positionRef as! AXValue), .cgPoint, &position)
        }
        if let sizeRef, CFGetTypeID(sizeRef) == AXValueGetTypeID() {
            AXValueGetValue((sizeRef as! AXValue), .cgSize, &size)
        }
        guard size.width > 0, size.height > 0 else { return nil }

        guard let infoList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: AnyObject]] else {
            return nil
        }

        for info in infoList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid else { continue }
            guard let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] else { continue }

            let x = bounds["X"] ?? -1
            let y = bounds["Y"] ?? -1
            let w = bounds["Width"] ?? -1
            let h = bounds["Height"] ?? -1
            let tolerance: CGFloat = 2

            if abs(x - position.x) < tolerance, abs(y - position.y) < tolerance,
               abs(w - size.width) < tolerance, abs(h - size.height) < tolerance {
                return info[kCGWindowNumber as String] as? CGWindowID
            }
        }
        return nil
    }
}
