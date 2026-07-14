import AppKit
import SwiftUI

/// Panel flotante siempre-visible con la lista de personajes, alternativa al
/// menú desplegable para cambiar de cuenta con el ratón. `.nonactivatingPanel`
/// para que aparecer/clicar en él no le robe el foco a Dofus más de lo
/// necesario — el propio `focus()` ya activa la app de Dofus al hacer clic.
final class FloatingPanelController {
    private static let autosaveName = "DofusTabsFloatingPanel"

    private var panel: NSPanel?
    private let windowManager: DofusWindowManager
    private let hotkeyStore: HotkeyPreferencesStore

    var isVisible: Bool { panel?.isVisible ?? false }

    init(windowManager: DofusWindowManager, hotkeyStore: HotkeyPreferencesStore) {
        self.windowManager = windowManager
        self.hotkeyStore = hotkeyStore
    }

    func show() {
        if panel == nil {
            panel = makePanel()
        }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    private func makePanel() -> NSPanel {
        let hostingController = NSHostingController(
            rootView: FloatingPanelView(windowManager: windowManager, hotkeyStore: hotkeyStore)
        )
        hostingController.sizingOptions = [.preferredContentSize]

        let panel = NSPanel(contentViewController: hostingController)
        panel.styleMask = [.nonactivatingPanel, .titled, .fullSizeContentView]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let hadSavedFrame = panel.setFrameUsingName(Self.autosaveName)
        panel.setFrameAutosaveName(Self.autosaveName)
        if !hadSavedFrame, let screen = NSScreen.main {
            let origin = NSPoint(x: screen.visibleFrame.minX + 24, y: screen.visibleFrame.maxY - 24)
            panel.setFrameTopLeftPoint(origin)
        }

        return panel
    }
}
