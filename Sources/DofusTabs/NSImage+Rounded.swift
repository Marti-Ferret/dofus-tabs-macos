import AppKit

extension NSImage {
    /// Recorta la imagen con esquinas redondeadas — usado para que las miniaturas
    /// de ventana en el menú se vean como iconos de app en vez de screenshots secos.
    func roundedCorners(radius: CGFloat) -> NSImage {
        let rounded = NSImage(size: size)
        rounded.lockFocus()
        defer { rounded.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
        draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        return rounded
    }
}
