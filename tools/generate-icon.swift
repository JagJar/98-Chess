#!/usr/bin/env swift
//
// generate-icon.swift — renders a 1024×1024 Win98-themed chess app icon.
// Run from the repo root:
//   swift tools/generate-icon.swift
// Output: Chess98/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
import AppKit
import CoreText
import Foundation

let pixelSize: Int = 1024
let outPath = "Chess98/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

let size = CGFloat(pixelSize)

// MARK: Palette
let teal       = CGColor(red: 0x00/255.0, green: 0x80/255.0, blue: 0x80/255.0, alpha: 1)
let face       = CGColor(red: 0xC0/255.0, green: 0xC0/255.0, blue: 0xC0/255.0, alpha: 1)
let titleBar   = CGColor(red: 0x00/255.0, green: 0x00/255.0, blue: 0x80/255.0, alpha: 1)
let highlight  = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let darkShadow = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
let lightGray  = CGColor(red: 0xDF/255.0, green: 0xDF/255.0, blue: 0xDF/255.0, alpha: 1)
let shadow     = CGColor(red: 0x80/255.0, green: 0x80/255.0, blue: 0x80/255.0, alpha: 1)
let inkBlack   = CGColor(red: 0, green: 0, blue: 0, alpha: 1)

// MARK: Geometry
let inset: CGFloat = size * 0.08
let windowRect = CGRect(
    x: inset,
    y: inset,
    width: size - 2 * inset,
    height: size - 2 * inset
)
let titleBarHeight: CGFloat = windowRect.height * 0.16
let bevelOuter: CGFloat = 12
let bevelInner: CGFloat = 12

// Create a 1024×1024 RGBA bitmap context
let cs = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
guard let ctx = CGContext(
    data: nil,
    width: pixelSize,
    height: pixelSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: cs,
    bitmapInfo: bitmapInfo
) else {
    print("Failed to create bitmap context")
    exit(1)
}

// Background
ctx.setFillColor(teal)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Window face
ctx.setFillColor(face)
ctx.fill(windowRect)

// Title bar at top
let titleBarRect = CGRect(
    x: windowRect.minX,
    y: windowRect.maxY - titleBarHeight,
    width: windowRect.width,
    height: titleBarHeight
)
ctx.setFillColor(titleBar)
ctx.fill(titleBarRect)

// Outer bevel — top + left highlight, bottom + right darkShadow
ctx.setFillColor(highlight)
ctx.fill(CGRect(x: windowRect.minX, y: windowRect.maxY - bevelOuter, width: windowRect.width, height: bevelOuter))
ctx.fill(CGRect(x: windowRect.minX, y: windowRect.minY, width: bevelOuter, height: windowRect.height))
ctx.setFillColor(darkShadow)
ctx.fill(CGRect(x: windowRect.minX, y: windowRect.minY, width: windowRect.width, height: bevelOuter))
ctx.fill(CGRect(x: windowRect.maxX - bevelOuter, y: windowRect.minY, width: bevelOuter, height: windowRect.height))

// Inner bevel
let innerRect = windowRect.insetBy(dx: bevelOuter, dy: bevelOuter)
ctx.setFillColor(lightGray)
ctx.fill(CGRect(x: innerRect.minX, y: innerRect.maxY - bevelInner, width: innerRect.width, height: bevelInner))
ctx.fill(CGRect(x: innerRect.minX, y: innerRect.minY, width: bevelInner, height: innerRect.height))
ctx.setFillColor(shadow)
ctx.fill(CGRect(x: innerRect.minX, y: innerRect.minY, width: innerRect.width, height: bevelInner))
ctx.fill(CGRect(x: innerRect.maxX - bevelInner, y: innerRect.minY, width: bevelInner, height: innerRect.height))

// White king Unicode glyph centered in the body area
let kingArea = CGRect(
    x: windowRect.minX,
    y: windowRect.minY,
    width: windowRect.width,
    height: windowRect.height - titleBarHeight
)
let kingString = "\u{2654}\u{FE0E}" // white king + text-style variation selector
let fontSize: CGFloat = kingArea.height * 0.85

let nsFont = NSFont.systemFont(ofSize: fontSize)
let ctFont = nsFont as CTFont
let attrs: [NSAttributedString.Key: Any] = [
    .font: nsFont,
    .foregroundColor: NSColor.black,
]
let attributed = NSAttributedString(string: kingString, attributes: attrs)
let line = CTLineCreateWithAttributedString(attributed)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
let glyphX = kingArea.midX - bounds.width / 2 - bounds.minX
let glyphY = kingArea.midY - bounds.height / 2 - bounds.minY

ctx.saveGState()
ctx.textPosition = CGPoint(x: glyphX, y: glyphY)
CTLineDraw(line, ctx)
ctx.restoreGState()
_ = ctFont // silence unused warning

// Output PNG
guard let cgImage = ctx.makeImage() else {
    print("makeImage failed")
    exit(1)
}
let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    print("PNG conversion failed")
    exit(1)
}

let outURL = URL(fileURLWithPath: outPath)
try png.write(to: outURL)
print("wrote \(outURL.path) at \(cgImage.width)×\(cgImage.height) (\(png.count) bytes)")
