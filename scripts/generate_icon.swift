#!/usr/bin/env swift
import AppKit

// Generates a rounded-square app icon: dark green gradient background with a white car glyph,
// rendered at every size macOS expects, written into Resources/AppIcon.iconset.

let sizes: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x")
]

let outDir = URL(fileURLWithPath: "Resources/AppIcon.iconset")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func makeIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }

    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let corner = s * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)

    let colors = [
        NSColor(calibratedRed: 0.03, green: 0.20, blue: 0.14, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.05, green: 0.55, blue: 0.30, alpha: 1).cgColor
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!

    ctx.saveGState()
    path.addClip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.restoreGState()

    // subtle inner highlight ring
    ctx.saveGState()
    let ring = NSBezierPath(roundedRect: rect.insetBy(dx: s * 0.02, dy: s * 0.02), xRadius: corner, yRadius: corner)
    NSColor.white.withAlphaComponent(0.10).setStroke()
    ring.lineWidth = s * 0.01
    ring.stroke()
    ctx.restoreGState()

    // Car glyph (SF Symbol) in white, centered
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: s * 0.5, weight: .bold)
    if let symbol = NSImage(systemSymbolName: "bolt.car.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let tinted = NSImage(size: symbol.size)
        tinted.lockFocus()
        NSColor.white.set()
        let symRect = NSRect(origin: .zero, size: symbol.size)
        symbol.draw(in: symRect)
        symRect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        let targetSize = s * 0.56
        let scale = targetSize / max(symbol.size.width, symbol.size.height)
        let drawSize = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
        let origin = CGPoint(x: (s - drawSize.width) / 2, y: (s - drawSize.height) / 2 - s * 0.02)
        tinted.draw(in: CGRect(origin: origin, size: drawSize), from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()
    return image
}

for (size, name) in sizes {
    let image = makeIcon(size: size)
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    let url = outDir.appendingPathComponent("\(name).png")
    try? png.write(to: url)
    print("Wrote \(url.path)")
}
