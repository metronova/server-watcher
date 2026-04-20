#!/usr/bin/swift
import AppKit

let size: CGFloat = 1024

let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
    let cs = CGColorSpaceCreateDeviceRGB()

    // === BACKGROUND ===
    let bgGrad = CGGradient(
        colorsSpace: cs,
        colors: [
            CGColor(red: 0.052, green: 0.106, blue: 0.165, alpha: 1),
            CGColor(red: 0.082, green: 0.227, blue: 0.502, alpha: 1)
        ] as CFArray,
        locations: [0, 1])!
    ctx.drawLinearGradient(bgGrad,
        start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

    // Subtle center glow
    let glowGrad = CGGradient(
        colorsSpace: cs,
        colors: [
            CGColor(red: 0.15, green: 0.40, blue: 0.80, alpha: 0.30),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray,
        locations: [0, 1])!
    ctx.drawRadialGradient(glowGrad,
        startCenter: CGPoint(x: size/2, y: size/2), startRadius: 0,
        endCenter: CGPoint(x: size/2, y: size/2), endRadius: 510, options: [])

    // === SERVER ROWS ===
    let rowW: CGFloat = 580
    let rowH: CGFloat = 80
    let rowGap: CGFloat = 20
    let numRows = 3
    let totalH = CGFloat(numRows) * rowH + CGFloat(numRows - 1) * rowGap  // 280
    let rowStartX = (size - rowW) / 2
    let rowStartY: CGFloat = 310
    let offlineIdx = 1

    for i in 0..<numRows {
        let ry = rowStartY + CGFloat(i) * (rowH + rowGap)
        let rowRect = CGRect(x: rowStartX, y: ry, width: rowW, height: rowH)
        let isOff = (i == offlineIdx)

        // Row fill
        let rowPath = CGPath(roundedRect: rowRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: isOff ? 0.06 : 0.12))
        ctx.addPath(rowPath); ctx.fillPath()

        // Row border
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: isOff ? 0.10 : 0.22))
        ctx.setLineWidth(1.5)
        ctx.addPath(rowPath); ctx.strokePath()

        // Left accent stripe
        let stripeRect = CGRect(x: rowStartX + 1.5, y: ry + 14, width: 7, height: rowH - 28)
        let stripePath = CGPath(roundedRect: stripeRect, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil)
        ctx.setFillColor(isOff
            ? CGColor(red: 0.95, green: 0.28, blue: 0.28, alpha: 0.80)
            : CGColor(red: 0.20, green: 0.92, blue: 0.45, alpha: 0.80))
        ctx.addPath(stripePath); ctx.fillPath()

        // Content lines (fake text)
        let la: CGFloat = isOff ? 0.12 : 0.26
        let lr1 = CGRect(x: rowStartX + 28, y: ry + rowH * 0.60, width: 165, height: 7)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: la))
        ctx.addPath(CGPath(roundedRect: lr1, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil)); ctx.fillPath()

        let lr2 = CGRect(x: rowStartX + 28, y: ry + rowH * 0.28, width: 100, height: 5)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: la * 0.60))
        ctx.addPath(CGPath(roundedRect: lr2, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)); ctx.fillPath()

        // LED dot
        let ledR: CGFloat = 12
        let ledCX = rowStartX + rowW - 50
        let ledCY = ry + rowH / 2
        let ledC = isOff
            ? CGColor(red: 0.98, green: 0.25, blue: 0.25, alpha: 1)
            : CGColor(red: 0.20, green: 0.92, blue: 0.45, alpha: 1)
        let glowC = isOff
            ? CGColor(red: 1, green: 0.10, blue: 0.10, alpha: 0.28)
            : CGColor(red: 0.10, green: 1, blue: 0.35, alpha: 0.22)

        let gr = ledR * 2.0
        ctx.setFillColor(glowC)
        ctx.fillEllipse(in: CGRect(x: ledCX - gr, y: ledCY - gr, width: gr*2, height: gr*2))
        ctx.setFillColor(ledC)
        ctx.fillEllipse(in: CGRect(x: ledCX - ledR, y: ledCY - ledR, width: ledR*2, height: ledR*2))
    }

    // === SIGNAL ARCS ===
    let topOfRows = rowStartY + totalH  // 590
    let arcCX = size / 2               // 512
    let arcCY = topOfRows + 60.0       // 650

    // counterclockwise arc from 30° to 150° = upward arch (WiFi style)
    let aStart = CGFloat.pi / 6        // 30°
    let aEnd   = CGFloat.pi * 5 / 6   // 150°

    let arcs: [(CGFloat, CGFloat, CGFloat)] = [
        (50,  10, 1.00),
        (95,  7,  0.62),
        (140, 5,  0.30)
    ]
    ctx.setLineCap(.round)
    for (r, lw, a) in arcs {
        ctx.setStrokeColor(CGColor(red: 0.20, green: 0.92, blue: 0.45, alpha: a))
        ctx.setLineWidth(lw)
        ctx.addArc(center: CGPoint(x: arcCX, y: arcCY),
                   radius: r, startAngle: aStart, endAngle: aEnd, clockwise: false)
        ctx.strokePath()
    }

    // Arc center glow + dot
    let dotR: CGFloat = 11
    ctx.setFillColor(CGColor(red: 0.15, green: 1, blue: 0.40, alpha: 0.28))
    ctx.fillEllipse(in: CGRect(x: arcCX - dotR*2.2, y: arcCY - dotR*2.2, width: dotR*4.4, height: dotR*4.4))
    ctx.setFillColor(CGColor(red: 0.20, green: 0.92, blue: 0.45, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: arcCX - dotR, y: arcCY - dotR, width: dotR*2, height: dotR*2))

    // Dashed connector line: dot → top of servers
    ctx.setStrokeColor(CGColor(red: 0.20, green: 0.92, blue: 0.45, alpha: 0.20))
    ctx.setLineWidth(3)
    ctx.setLineDash(phase: 0, lengths: [8, 6])
    ctx.move(to: CGPoint(x: arcCX, y: arcCY - dotR - 2))
    ctx.addLine(to: CGPoint(x: arcCX, y: topOfRows + 4))
    ctx.strokePath()
    ctx.setLineDash(phase: 0, lengths: [])

    return true
}

guard let tiff = image.tiffRepresentation,
      let bmp  = NSBitmapImageRep(data: tiff),
      let png  = bmp.representation(using: .png, properties: [:]) else {
    fputs("Error: could not render PNG\n", stderr); exit(1)
}

let dest = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"
do {
    try png.write(to: URL(fileURLWithPath: dest))
    print("Saved: \(dest)")
} catch {
    fputs("Error writing file: \(error)\n", stderr); exit(1)
}
