import SwiftUI
import Carbon.HIToolbox

/// Botón tipo "clica y pulsa la tecla que quieras" para reasignar un atajo,
/// igual que el "key capture mode" que ya tienen Organizer-Dofus/Dofus Tabs
/// en Windows.
struct HotkeyRecorderView: View {
    @Binding var binding: HotkeyBinding
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(isRecording ? L10n.hotkeyRecordingPlaceholder : binding.displayString)
                .frame(minWidth: 76)
        }
        .buttonStyle(.bordered)
        .onDisappear(perform: stopRecording)
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }

            let modifiers = HotkeyBinding.carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else {
                // Sin modificador se ignora: si no, un atajo como "A" sola
                // secuestraría esa tecla en todo el sistema.
                return nil
            }

            binding = HotkeyBinding(keyCode: UInt32(event.keyCode), modifiers: modifiers)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
