import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let maxDirectSlots = 9

    private static let fallbackThumbnail = NSImage(
        systemSymbolName: "person.crop.square.fill",
        accessibilityDescription: nil
    )

    private var statusItem: NSStatusItem!
    private let windowManager = DofusWindowManager()
    private let hotkeyStore = HotkeyPreferencesStore()
    private var cycleHotkey: HotkeyManager?
    private var arrangeHotkey: HotkeyManager?
    private var directHotkeys: [HotkeyManager] = []
    private var lastHotkeySignature: [String] = []
    private var refreshTimer: Timer?
    private var settingsWindowController: SettingsWindowController?
    private lazy var floatingPanelController = FloatingPanelController(
        windowManager: windowManager,
        hotkeyStore: hotkeyStore
    )
    private let floatingPanelVisibleKey = "com.martiferretc.dofustabs.floatingPanelVisible"
    private var availableUpdate: UpdateChecker.UpdateResult?

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccessibilityPermissionIfNeeded()
        requestScreenRecordingPermissionIfNeeded()

        // variableLength (no squareLength) para que el ancho se ajuste al texto
        // "DT" / "DT 4" — squareLength es un cuadrado fijo muy estrecho pensado
        // para un icono, y partía el texto en dos líneas.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "DT"

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        refreshAndSyncHotkeys()
        updateStatusItemTitle()
        rebuildMenu(includeThumbnails: false)
        registerGlobalActionHotkeys()

        // Refresco periódico ligero (sin capturas de pantalla) para que el
        // conteo de personajes y los atajos directos estén al día aunque no
        // se haya abierto el menú.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refreshAndSyncHotkeys()
            self?.updateStatusItemTitle()
            self?.rebuildMenu(includeThumbnails: false)
        }

        if UserDefaults.standard.bool(forKey: floatingPanelVisibleKey) {
            floatingPanelController.show()
        }

        // Comprobación silenciosa al arrancar: si hay versión nueva, solo se
        // añade el aviso al menú (sin interrumpir con una alerta). El chequeo
        // manual desde el menú sí da feedback explícito, éste no.
        UpdateChecker.checkForUpdate { [weak self] result in
            guard let self, let result else { return }
            self.availableUpdate = result
            self.rebuildMenu(includeThumbnails: false)
        }
    }

    private func requestAccessibilityPermissionIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: [String: Any] = [promptKey: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func requestScreenRecordingPermissionIfNeeded() {
        // Las miniaturas de ventana necesitan este permiso además del de Accesibilidad.
        if !CGPreflightScreenCaptureAccess() {
            _ = CGRequestScreenCaptureAccess()
        }
    }

    /// Ciclar y organizar ventanas usan la combinación que haya elegido el
    /// usuario en Ajustes (por defecto Cmd+1 y Cmd+0). Se vuelve a llamar cada
    /// vez que Ajustes notifica un cambio, por si el usuario reasignó alguna.
    private func registerGlobalActionHotkeys() {
        let cycle = hotkeyStore.cycleBinding
        cycleHotkey = HotkeyManager(keyCode: cycle.keyCode, modifiers: cycle.modifiers) { [weak self] in
            self?.windowManager.refresh()
            self?.windowManager.focusNextWindow()
        }

        let arrange = hotkeyStore.arrangeBinding
        arrangeHotkey = HotkeyManager(keyCode: arrange.keyCode, modifiers: arrange.modifiers) { [weak self] in
            self?.arrangeWindowsNow()
        }
    }

    private func refreshAndSyncHotkeys() {
        windowManager.refresh()
        syncDirectHotkeys()
    }

    /// Registra los atajos directos configurados sobre las ventanas activas
    /// (no excluidas), en el orden ya estabilizado por `CharacterOrderStore`.
    /// Solo se re-registran si el conjunto de personajes o las combinaciones
    /// de tecla han cambiado de verdad, para no desregistrar/registrar en
    /// cada refresco de 3s sin motivo.
    ///
    /// Cada atajo busca la ventana actual por posición al pulsarse (no captura
    /// la `DofusWindow`/AXUIElement del momento del registro): si una cuenta se
    /// desconecta y reconecta con el mismo nombre, el conjunto de nombres no
    /// cambia y no se re-sincroniza, así que un atajo que capturase la ventana
    /// vieja quedaría apuntando a un AXUIElement ya inválido.
    private func syncDirectHotkeys() {
        let active = windowManager.activeWindows
        let slotCount = min(active.count, Self.maxDirectSlots)

        let names = active.map { $0.characterName }
        let bindings = (0..<slotCount).map { hotkeyStore.directBinding(at: $0) }
        let signature = names + bindings.map { "\($0.keyCode)-\($0.modifiers)" }
        guard signature != lastHotkeySignature else { return }
        lastHotkeySignature = signature

        directHotkeys.removeAll()

        for index in 0..<slotCount {
            let binding = hotkeyStore.directBinding(at: index)
            let hotkey = HotkeyManager(keyCode: binding.keyCode, modifiers: binding.modifiers) { [weak self] in
                guard let self else { return }
                let current = self.windowManager.activeWindows
                guard index < current.count else { return }
                self.windowManager.focus(current[index])
            }
            directHotkeys.append(hotkey)
        }
    }

    /// Muestra cuántas cuentas de Dofus están detectadas ahora mismo, de un
    /// vistazo, sin tener que abrir el menú.
    private func updateStatusItemTitle() {
        let count = windowManager.windows.count
        statusItem.button?.title = count > 0 ? "DT \(count)" : "DT"
    }

    private func arrangeWindowsNow() {
        windowManager.refresh()
        WindowArranger.tile(windowManager.activeWindows)
    }

    /// Se llama justo antes de mostrar el menú: es el momento de pedir las
    /// miniaturas (capturas de pantalla), en vez de hacerlo en cada refresh
    /// periódico de fondo.
    func menuNeedsUpdate(_ menu: NSMenu) {
        refreshAndSyncHotkeys()
        updateStatusItemTitle()
        rebuildMenu(includeThumbnails: true)
    }

    private func rebuildMenu(includeThumbnails: Bool) {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        if let availableUpdate {
            let updateItem = NSMenuItem(
                title: L10n.menuUpdateAvailable(version: availableUpdate.version),
                action: #selector(openUpdateURL),
                keyEquivalent: ""
            )
            updateItem.target = self
            menu.addItem(updateItem)
            menu.addItem(NSMenuItem.separator())
        }

        let windows = windowManager.windows
        let active = windowManager.activeWindows

        if windows.isEmpty {
            let emptyItem = NSMenuItem(title: L10n.menuNoDofusDetected, action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for window in windows {
                let activeIndex = active.firstIndex(where: { $0.characterName == window.characterName })

                let item = NSMenuItem(
                    title: window.characterName,
                    action: #selector(selectWindow(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = window

                let isExcluded = activeIndex == nil
                var titleText = window.characterName
                if let activeIndex, activeIndex < Self.maxDirectSlots {
                    titleText += "   \(hotkeyStore.directBinding(at: activeIndex).displayString)"
                } else if isExcluded {
                    titleText += L10n.menuExcludedSuffix
                }

                item.attributedTitle = NSAttributedString(
                    string: titleText,
                    attributes: [
                        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                        .foregroundColor: isExcluded ? NSColor.secondaryLabelColor : NSColor.labelColor
                    ]
                )

                item.image = includeThumbnails
                    ? (windowManager.thumbnail(for: window) ?? Self.fallbackThumbnail)
                    : Self.fallbackThumbnail

                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let arrangeItem = NSMenuItem(
            title: "\(L10n.menuArrangeWindows)   \(hotkeyStore.arrangeBinding.displayString)",
            action: #selector(arrangeNow),
            keyEquivalent: ""
        )
        arrangeItem.target = self
        menu.addItem(arrangeItem)

        let floatingPanelItem = NSMenuItem(
            title: L10n.menuFloatingPanel,
            action: #selector(toggleFloatingPanel),
            keyEquivalent: ""
        )
        floatingPanelItem.target = self
        floatingPanelItem.state = floatingPanelController.isVisible ? .on : .off
        menu.addItem(floatingPanelItem)

        let settingsItem = NSMenuItem(title: L10n.menuSettings, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: L10n.menuRefresh, action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let checkUpdatesItem = NSMenuItem(
            title: L10n.menuCheckForUpdates,
            action: #selector(checkForUpdatesNow),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)

        let quitItem = NSMenuItem(title: L10n.menuQuit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func selectWindow(_ sender: NSMenuItem) {
        guard let window = sender.representedObject as? DofusWindow else { return }
        windowManager.focus(window)
    }

    @objc private func arrangeNow() {
        arrangeWindowsNow()
    }

    @objc private func toggleFloatingPanel() {
        floatingPanelController.toggle()
        UserDefaults.standard.set(floatingPanelController.isVisible, forKey: floatingPanelVisibleKey)
    }

    @objc private func openUpdateURL() {
        guard let availableUpdate else { return }
        NSWorkspace.shared.open(availableUpdate.releaseURL)
    }

    /// A diferencia del chequeo silencioso al arrancar, este sí da feedback
    /// explícito (con alerta) en los dos casos — lo pidió el usuario a propósito.
    @objc private func checkForUpdatesNow() {
        UpdateChecker.checkForUpdate { [weak self] result in
            guard let self else { return }

            guard let result else {
                self.presentAlert(
                    title: L10n.updateUpToDateTitle,
                    message: L10n.updateUpToDateMessage,
                    buttons: [L10n.updateOkButton]
                )
                return
            }

            self.availableUpdate = result
            self.rebuildMenu(includeThumbnails: false)

            let choice = self.presentAlert(
                title: L10n.updateAvailableTitle,
                message: L10n.updateAvailableMessage(version: result.version),
                buttons: [L10n.updateDownloadButton, L10n.updateLaterButton]
            )
            if choice == .alertFirstButtonReturn {
                NSWorkspace.shared.open(result.releaseURL)
            }
        }
    }

    @discardableResult
    private func presentAlert(title: String, message: String, buttons: [String]) -> NSApplication.ModalResponse {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        for button in buttons {
            alert.addButton(withTitle: button)
        }
        return alert.runModal()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            let controller = SettingsWindowController(
                windowManager: windowManager,
                hotkeyStore: hotkeyStore,
                onArrangeNow: { [weak self] in self?.arrangeWindowsNow() },
                onChanged: { [weak self] in
                    self?.registerGlobalActionHotkeys()
                    self?.lastHotkeySignature = []
                    self?.refreshAndSyncHotkeys()
                    self?.updateStatusItemTitle()
                    self?.rebuildMenu(includeThumbnails: false)
                }
            )
            settingsWindowController = controller

            // Los ajustes se comportan como una ventana normal (visible en Cmd+Tab)
            // mientras está abierta; la app vuelve a ser solo de barra de menú al cerrarla.
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: controller.window,
                queue: .main
            ) { _ in
                NSApp.setActivationPolicy(.accessory)
            }
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func refreshNow() {
        refreshAndSyncHotkeys()
        updateStatusItemTitle()
        rebuildMenu(includeThumbnails: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
