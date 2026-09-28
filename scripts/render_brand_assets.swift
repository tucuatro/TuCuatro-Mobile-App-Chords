import AppKit
import CoreImage
import Foundation

guard CommandLine.arguments.count == 4 else {
    fputs("usage: render_brand_assets.swift <canonical.png> <app-icon.png> <mark.png>\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let appIconURL = URL(fileURLWithPath: CommandLine.arguments[2])
let markURL = URL(fileURLWithPath: CommandLine.arguments[3])

guard
    let sourceData = try? Data(contentsOf: sourceURL),
    let sourceImage = NSImage(data: sourceData),
    let sourceCG = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("Unable to read canonical TuCuatro mark.\n", stderr)
    exit(65)
}

let width = sourceCG.width
let height = sourceCG.height
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to inspect canonical mark.\n", stderr)
    exit(66)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSImage(cgImage: sourceCG, size: NSSize(width: width, height: height)).draw(
    in: NSRect(x: 0, y: 0, width: width, height: height),
    from: .zero,
    operation: .copy,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

var minX = width
var minY = height
var maxX = -1
var maxY = -1

for y in 0..<height {
    for x in 0..<width {
        if bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0 > 0.02 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

guard maxX >= minX, maxY >= minY else {
    fputs("Canonical mark has no visible pixels.\n", stderr)
    exit(67)
}

let cropRect = CGRect(
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1
)

guard let cropped = sourceCG.cropping(to: cropRect) else {
    fputs("Unable to crop canonical mark.\n", stderr)
    exit(68)
}

let input = CIImage(cgImage: cropped)
guard let filter = CIFilter(name: "CIColorMatrix") else {
    fputs("Unable to create color filter.\n", stderr)
    exit(69)
}

filter.setValue(input, forKey: kCIInputImageKey)
filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
filter.setValue(CIVector(x: 1, y: 1, z: 1, w: 0), forKey: "inputBiasVector")

guard
    let tinted = filter.outputImage,
    let tintedCG = CIContext(options: nil).createCGImage(tinted, from: tinted.extent)
else {
    fputs("Unable to tint canonical mark.\n", stderr)
    exit(70)
}

let markRep = NSBitmapImageRep(cgImage: tintedCG)
guard let markPNG = markRep.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode transparent mark PNG.\n", stderr)
    exit(71)
}
try markPNG.write(to: markURL, options: .atomic)

let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)
image.lockFocus()

NSColor(
    calibratedRed: 254.0 / 255.0,
    green: 160.0 / 255.0,
    blue: 47.0 / 255.0,
    alpha: 1
).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()

let markHeight: CGFloat = 619
let aspect = CGFloat(tintedCG.width) / CGFloat(tintedCG.height)
let markWidth = markHeight * aspect
let markRect = NSRect(
    x: (1024 - markWidth) / 2,
    y: (1024 - markHeight) / 2,
    width: markWidth,
    height: markHeight
)

NSImage(cgImage: tintedCG, size: NSSize(width: tintedCG.width, height: tintedCG.height)).draw(
    in: markRect,
    from: NSRect(x: 0, y: 0, width: tintedCG.width, height: tintedCG.height),
    operation: .sourceOver,
    fraction: 1,
    respectFlipped: true,
    hints: [.interpolation: NSImageInterpolation.high]
)
image.unlockFocus()

guard let opaque = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 1024,
    pixelsHigh: 1024,
    bitsPerSample: 8,
    samplesPerPixel: 3,
    hasAlpha: false,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to create opaque icon bitmap.\n", stderr)
    exit(72)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: opaque)
image.draw(
    in: NSRect(origin: .zero, size: canvas),
    from: NSRect(origin: .zero, size: canvas),
    operation: .copy,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let iconPNG = opaque.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode app icon PNG.\n", stderr)
    exit(73)
}
try iconPNG.write(to: appIconURL, options: .atomic)

print("Generated TuCuatro Chords brand assets.")
