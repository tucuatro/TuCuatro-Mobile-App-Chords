import AppKit
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 4 else {
    fputs("usage: render_brand_assets.swift <canonical.png> <app-icon.png> <mark.png>\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let appIconURL = URL(fileURLWithPath: CommandLine.arguments[2])
let markURL = URL(fileURLWithPath: CommandLine.arguments[3])

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "TuCuatroBrand", code: 1)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "TuCuatroBrand", code: 2)
    }
}

guard
    let sourceData = try? Data(contentsOf: sourceURL),
    let sourceImage = NSImage(data: sourceData),
    let sourceCG = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("Unable to read canonical TuCuatro mark.\n", stderr)
    exit(65)
}

// Determine the non-transparent bounds of the canonical mark.
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

// Convert the exact canonical silhouette to solid white while preserving alpha.
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
    let tintedCG = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
        .createCGImage(tinted, from: tinted.extent)
else {
    fputs("Unable to tint canonical mark.\n", stderr)
    exit(70)
}

do {
    try writePNG(tintedCG, to: markURL)
} catch {
    fputs("Unable to encode transparent mark PNG.\n", stderr)
    exit(71)
}

// Build the App Store icon directly in a Core Graphics RGB bitmap.
// Avoid NSImage focus/drawing here: that path produced a black bitmap on the
// founder's Mac even though the transparent mark rendered correctly.
let iconSize = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: iconSize,
    height: iconSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fputs("Unable to create RGB app icon context.\n", stderr)
    exit(72)
}

context.setFillColor(
    CGColor(
        colorSpace: colorSpace,
        components: [254.0 / 255.0, 160.0 / 255.0, 47.0 / 255.0, 1]
    )!
)
context.fill(CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
context.interpolationQuality = .high

let markHeight: CGFloat = 619
let aspect = CGFloat(tintedCG.width) / CGFloat(tintedCG.height)
let markWidth = markHeight * aspect
let markRect = CGRect(
    x: (CGFloat(iconSize) - markWidth) / 2,
    y: (CGFloat(iconSize) - markHeight) / 2,
    width: markWidth,
    height: markHeight
)
context.draw(tintedCG, in: markRect)

guard let appIconCG = context.makeImage() else {
    fputs("Unable to finalize app icon image.\n", stderr)
    exit(73)
}

do {
    try writePNG(appIconCG, to: appIconURL)
} catch {
    fputs("Unable to encode app icon PNG.\n", stderr)
    exit(74)
}

print("Generated TuCuatro Chords brand assets.")
print("App icon: 1024x1024 RGB, #FEA02F background, canonical white mark.")
