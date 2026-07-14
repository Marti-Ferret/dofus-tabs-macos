import SwiftUI
import AppKit

/// Contenido del panel flotante: lista de personajes con miniatura, número
/// y atajo asignado (si tiene). Clic en una fila enfoca esa ventana — pensado
/// para cambiar de cuenta con el ratón sin tocar el teclado.
struct FloatingPanelView: View {
    let windowManager: DofusWindowManager
    let hotkeyStore: HotkeyPreferencesStore

    @State private var windows: [DofusWindow] = []
    @State private var refreshTimer: Timer?

    private static let fallbackThumbnail = NSImage(
        systemSymbolName: "person.crop.square.fill",
        accessibilityDescription: nil
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            dragHandle

            if windows.isEmpty {
                Text(L10n.settingsNoWindows)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(10)
            } else {
                ForEach(Array(windows.enumerated()), id: \.element.characterName) { index, window in
                    row(for: window, at: index)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 200)
        .background(.ultraThinMaterial)
        .onAppear {
            reload()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                reload()
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    /// Franja superior sin controles — arrastra el panel entero (ver `DragHandleView`).
    private var dragHandle: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 14)
        .background(WindowDragArea())
    }

    private func row(for window: DofusWindow, at index: Int) -> some View {
        let isExcluded = windowManager.isExcluded(window)
        let activeIndex = windowManager.activeWindows.firstIndex(where: { $0.characterName == window.characterName })

        return Button(action: { windowManager.focus(window) }) {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, alignment: .trailing)

                Image(nsImage: windowManager.thumbnail(for: window, maxDimension: 32) ?? Self.fallbackThumbnail ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(window.characterName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if let activeIndex, activeIndex < 9 {
                        Text(hotkeyStore.directBinding(at: activeIndex).displayString)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else if isExcluded {
                        Text(L10n.settingsExcludedFromRotation)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.06)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isExcluded ? 0.55 : 1.0)
    }

    private func reload() {
        windowManager.refresh()
        windows = windowManager.windows
    }
}

/// Puente a AppKit: un `mouseDown` en esta vista arrastra la ventana entera,
/// vía `NSWindow.performDrag(with:)` — más fiable que depender solo de
/// `isMovableByWindowBackground` con contenido SwiftUI encima.
private struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleView { DragHandleView() }
    func updateNSView(_ nsView: DragHandleView, context: Context) {}
}

final class DragHandleView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
