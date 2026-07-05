#!/usr/bin/env swift
import AppKit

// MARK: - Paleta (misma que generate-icon.swift, para que todo case)

let purple = NSColor(calibratedRed: 0.36, green: 0.20, blue: 0.85, alpha: 1.0)
let blue = NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.95, alpha: 1.0)
let ink = NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.18, alpha: 1.0)
let avatarPalette: [NSColor] = [
    NSColor(calibratedRed: 0.98, green: 0.55, blue: 0.42, alpha: 1.0),
    NSColor(calibratedRed: 0.35, green: 0.80, blue: 0.62, alpha: 1.0),
    NSColor(calibratedRed: 0.98, green: 0.75, blue: 0.30, alpha: 1.0),
    NSColor(calibratedRed: 0.55, green: 0.62, blue: 0.98, alpha: 1.0)
]

// MARK: - Helpers de dibujo

func fillBackground(size: NSSize, cornerRadius: CGFloat) {
    let rect = NSRect(origin: .zero, size: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSGradient(colors: [purple, blue])?.draw(in: path, angle: -35)

    // viñeta sutil para dar profundidad
    let vignette = NSGradient(colors: [NSColor.black.withAlphaComponent(0.0), NSColor.black.withAlphaComponent(0.16)])
    vignette?.draw(in: path, relativeCenterPosition: NSPoint(x: 0.3, y: 0.3))
}

func drawAppIconGlyph(in rect: NSRect) {
    let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.22, yRadius: rect.width * 0.22)
    NSGradient(colors: [purple, blue])?.draw(in: path, angle: -45)
    NSColor.white.withAlphaComponent(0.18).setStroke()
    path.lineWidth = max(1, rect.width * 0.01)
    path.stroke()

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: rect.width * 0.5, weight: .semibold)
    if let symbol = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let tinted = NSImage(size: symbol.size)
        tinted.lockFocus()
        NSColor.white.set()
        NSRect(origin: .zero, size: symbol.size).fill()
        symbol.draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1.0)
        tinted.unlockFocus()

        let origin = NSPoint(x: rect.midX - tinted.size.width / 2, y: rect.midY - tinted.size.height / 2)
        tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
}

func drawText(_ string: String, at point: NSPoint, size: CGFloat, weight: NSFont.Weight, color: NSColor, tracking: CGFloat = 0) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .kern: tracking
    ]
    NSAttributedString(string: string, attributes: attrs).draw(at: point)
}

func textWidth(_ string: String, size: CGFloat, weight: NSFont.Weight, tracking: CGFloat = 0) -> CGFloat {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .kern: tracking]
    return NSAttributedString(string: string, attributes: attrs).size().width
}

/// Panel tipo dropdown de la barra de menú, con filas de personajes falsas —
/// para dar contexto visual de qué hace la app de un vistazo.
func drawMenuMockup(in rect: NSRect, rowCount: Int) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -8)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let panelPath = NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16)
    NSColor(calibratedWhite: 0.99, alpha: 0.98).setFill()
    panelPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    let rowHeight = rect.height / CGFloat(rowCount + 1)
    let padding: CGFloat = rect.width * 0.08

    // cabecera "DT n"
    drawText("DT \(rowCount)", at: NSPoint(x: rect.minX + padding, y: rect.maxY - rowHeight * 0.72), size: rowHeight * 0.34, weight: .semibold, color: ink)

    let headerDivider = NSBezierPath()
    headerDivider.move(to: NSPoint(x: rect.minX + padding, y: rect.maxY - rowHeight))
    headerDivider.line(to: NSPoint(x: rect.maxX - padding, y: rect.maxY - rowHeight))
    NSColor(calibratedWhite: 0.85, alpha: 1.0).setStroke()
    headerDivider.lineWidth = 1
    headerDivider.stroke()

    for row in 0..<rowCount {
        let rowTop = rect.maxY - rowHeight * CGFloat(row + 2)
        let avatarSize = rowHeight * 0.56
        let avatarRect = NSRect(x: rect.minX + padding, y: rowTop + (rowHeight - avatarSize) / 2, width: avatarSize, height: avatarSize)
        let avatarPath = NSBezierPath(roundedRect: avatarRect, xRadius: avatarSize * 0.28, yRadius: avatarSize * 0.28)
        avatarPalette[row % avatarPalette.count].setFill()
        avatarPath.fill()

        drawText(
            "Personaje \(row + 1)",
            at: NSPoint(x: avatarRect.maxX + padding * 0.6, y: rowTop + rowHeight * 0.36),
            size: rowHeight * 0.3,
            weight: .medium,
            color: ink
        )

        let badgeText = "⌘\(row + 1)"
        let badgeSize = rowHeight * 0.26
        let badgeWidth = textWidth(badgeText, size: badgeSize, weight: .semibold) + badgeSize
        let badgeRect = NSRect(x: rect.maxX - padding - badgeWidth, y: rowTop + (rowHeight - badgeSize * 1.6) / 2, width: badgeWidth, height: badgeSize * 1.6)
        NSBezierPath(roundedRect: badgeRect, xRadius: badgeRect.height / 2, yRadius: badgeRect.height / 2).fill(withColor: NSColor(calibratedWhite: 0.92, alpha: 1.0))
        drawText(badgeText, at: NSPoint(x: badgeRect.minX + badgeSize * 0.5, y: badgeRect.minY + badgeSize * 0.32), size: badgeSize, weight: .semibold, color: ink.withAlphaComponent(0.75))
    }
}

extension NSBezierPath {
    func fill(withColor color: NSColor) {
        color.setFill()
        fill()
    }
}

// MARK: - Banner ancho para la cabecera del README

func renderBanner() -> NSImage {
    let size = NSSize(width: 1280, height: 400)
    let image = NSImage(size: size)
    image.lockFocus()

    fillBackground(size: size, cornerRadius: 28)

    let iconRect = NSRect(x: 90, y: size.height - 190, width: 88, height: 88)
    drawAppIconGlyph(in: iconRect)

    drawText("DOFUS TABS", at: NSPoint(x: iconRect.minX, y: iconRect.minY - 56), size: 44, weight: .bold, color: .white, tracking: 0.5)
    drawText("Organiza tus ventanas multicuenta en macOS", at: NSPoint(x: iconRect.minX, y: iconRect.minY - 92), size: 20, weight: .regular, color: NSColor.white.withAlphaComponent(0.85))
    drawText("Proyecto de fan · no oficial · sin afiliación con Ankama", at: NSPoint(x: iconRect.minX, y: 40), size: 14, weight: .regular, color: NSColor.white.withAlphaComponent(0.6))

    let mockupRect = NSRect(x: size.width - 460, y: 40, width: 380, height: 320)
    drawMenuMockup(in: mockupRect, rowCount: 4)

    image.unlockFocus()
    return image
}

// MARK: - Imagen social de GitHub (Open Graph)

func renderSocialPreview() -> NSImage {
    let size = NSSize(width: 1280, height: 640)
    let image = NSImage(size: size)
    image.lockFocus()

    fillBackground(size: size, cornerRadius: 0)

    let iconSize: CGFloat = 200
    let iconRect = NSRect(x: (size.width - iconSize) / 2, y: 300, width: iconSize, height: iconSize)
    drawAppIconGlyph(in: iconRect)

    let title = "DOFUS TABS"
    let titleSize: CGFloat = 68
    let titleWidth = textWidth(title, size: titleSize, weight: .bold, tracking: 1.0)
    drawText(title, at: NSPoint(x: (size.width - titleWidth) / 2, y: 200), size: titleSize, weight: .bold, color: .white, tracking: 1.0)

    let tagline = "Organiza tus ventanas multicuenta de Dofus en macOS"
    let taglineSize: CGFloat = 26
    let taglineWidth = textWidth(tagline, size: taglineSize, weight: .regular)
    drawText(tagline, at: NSPoint(x: (size.width - taglineWidth) / 2, y: 140), size: taglineSize, weight: .regular, color: NSColor.white.withAlphaComponent(0.85))

    image.unlockFocus()
    return image
}

// MARK: - Guardado

func pngData(from image: NSImage, size: NSSize) -> Data? {
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
    rep.size = size
    return rep.representation(using: .png, properties: [:])
}

// Se escriben en site/public/promo — es lo que Astro copia tal cual a
// docs/promo al compilar (ver site/astro.config.mjs, outDir: '../docs').
let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let projectRoot = scriptDir.deletingLastPathComponent()
let promoDir = projectRoot.appendingPathComponent("site/public/promo")
try? FileManager.default.createDirectory(at: promoDir, withIntermediateDirectories: true)

let banner = renderBanner()
if let data = pngData(from: banner, size: NSSize(width: 1280, height: 400)) {
    try data.write(to: promoDir.appendingPathComponent("readme-banner.png"))
}

let social = renderSocialPreview()
if let data = pngData(from: social, size: NSSize(width: 1280, height: 640)) {
    try data.write(to: promoDir.appendingPathComponent("github-social-preview.png"))
}

print("Imágenes generadas en \(promoDir.path)")
