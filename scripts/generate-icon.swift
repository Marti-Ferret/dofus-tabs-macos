#!/usr/bin/env swift
import AppKit

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

extension NSImage {
    /// Recolorea el canal alfa de la imagen (útil para "tintar" un SF Symbol).
    func tinted(with color: NSColor) -> NSImage {
        let tinted = NSImage(size: size)
        tinted.lockFocus()
        color.set()
        NSRect(origin: .zero, size: size).fill()
        draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1.0)
        tinted.unlockFocus()
        return tinted
    }
}

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.36, green: 0.20, blue: 0.85, alpha: 1.0),
        NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.95, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: -45)

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.5, weight: .semibold)
    if let symbol = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let tinted = symbol.tinted(with: .white)
        let symbolSize = tinted.size
        let origin = NSPoint(x: (CGFloat(size) - symbolSize.width) / 2, y: (CGFloat(size) - symbolSize.height) / 2)
        tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()
    return image
}

func pngData(from image: NSImage, size: Int) -> Data? {
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
    rep.size = NSSize(width: size, height: size)
    return rep.representation(using: .png, properties: [:])
}

let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let projectRoot = scriptDir.deletingLastPathComponent()
let iconsetURL = projectRoot.appendingPathComponent("Resources/AppIcon.iconset")

let fileManager = FileManager.default
try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for entry in sizes {
    let image = drawIcon(size: entry.size)
    guard let data = pngData(from: image, size: entry.size) else { continue }
    try data.write(to: iconsetURL.appendingPathComponent("\(entry.name).png"))
}

print("Iconset generado en \(iconsetURL.path)")
