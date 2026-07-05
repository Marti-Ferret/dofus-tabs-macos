import Carbon.HIToolbox
import AppKit

/// Registra un atajo global de verdad (no un `NSEvent` monitor, que solo observa
/// y no evita que la app enfocada también reciba la tecla). Usa la misma API de
/// bajo nivel (`RegisterEventHotKey`) que Carbon lleva ofreciendo desde siempre
/// y que apps como Alfred/Rectangle siguen usando para esto en macOS.
final class HotkeyManager {
    private static var registry: [UInt32: HotkeyManager] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerInstalled = false

    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID: UInt32
    private let callback: () -> Void

    init(keyCode: UInt32 = UInt32(kVK_ANSI_1), modifiers: UInt32 = UInt32(cmdKey), action: @escaping () -> Void) {
        self.callback = action
        self.hotKeyID = HotkeyManager.nextID
        HotkeyManager.nextID += 1
        HotkeyManager.registry[hotKeyID] = self

        HotkeyManager.installHandlerIfNeeded()

        let signature: OSType = 0x4454_4142 // 'DTAB' como FourCharCode
        let eventHotKeyID = EventHotKeyID(signature: signature, id: hotKeyID)
        RegisterEventHotKey(keyCode, modifiers, eventHotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            HotkeyManager.registry[hotKeyID.id]?.callback()
            return noErr
        }, 1, &eventType, nil, nil)
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        HotkeyManager.registry[hotKeyID] = nil
    }
}
