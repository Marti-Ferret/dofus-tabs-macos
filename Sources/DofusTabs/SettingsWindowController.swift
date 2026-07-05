import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    convenience init(
        windowManager: DofusWindowManager,
        hotkeyStore: HotkeyPreferencesStore,
        onArrangeNow: @escaping () -> Void,
        onChanged: @escaping () -> Void
    ) {
        let rootView = SettingsView(
            windowManager: windowManager,
            hotkeyStore: hotkeyStore,
            onArrangeNow: onArrangeNow,
            onChanged: onChanged
        )
        let hostingController = NSHostingController(rootView: rootView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = L10n.settingsWindowTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false

        self.init(window: window)
    }
}
