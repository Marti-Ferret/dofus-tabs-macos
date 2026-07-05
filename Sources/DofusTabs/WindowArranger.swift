import AppKit
import ApplicationServices

/// Organiza las ventanas de Dofus en una cuadrícula que ocupa el área visible
/// de la pantalla principal (la que tiene la barra de menú).
///
/// Nadie en el ecosistema de Dofus (Windows o Mac) ofrece esto hoy — es el
/// diferenciador frente a la competencia (ver docs/market-research.md §2.1).
enum WindowArranger {
    static func tile(_ windows: [DofusWindow]) {
        guard !windows.isEmpty, let screen = NSScreen.screens.first else { return }

        // NSScreen usa coordenadas con origen abajo-izquierda; la Accessibility
        // API (igual que CoreGraphics) usa origen arriba-izquierda de la
        // pantalla principal. Hay que convertir cada celda de un sistema a otro.
        let visible = screen.visibleFrame
        let primaryHeight = screen.frame.height

        let count = windows.count
        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))

        let cellWidth = visible.width / CGFloat(columns)
        let cellHeight = visible.height / CGFloat(rows)

        for (index, window) in windows.enumerated() {
            let column = index % columns
            let row = index / columns

            let cellOriginXAppKit = visible.minX + CGFloat(column) * cellWidth
            let cellTopYAppKit = visible.maxY - CGFloat(row) * cellHeight
            let axY = primaryHeight - cellTopYAppKit

            var position = CGPoint(x: cellOriginXAppKit, y: axY)
            var size = CGSize(width: cellWidth, height: cellHeight)

            if let positionValue = AXValueCreate(.cgPoint, &position) {
                AXUIElementSetAttributeValue(window.axElement, kAXPositionAttribute as CFString, positionValue)
            }
            if let sizeValue = AXValueCreate(.cgSize, &size) {
                AXUIElementSetAttributeValue(window.axElement, kAXSizeAttribute as CFString, sizeValue)
            }
        }
    }
}
