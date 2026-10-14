#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/TickBar.app"
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_OUTPUT="$PROJECT_ROOT/public/downloads/TickBar-macOS-Universal.dmg"

mkdir -p "$BUILD_DIR" "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$DMG_STAGING" "$PROJECT_ROOT/public/downloads"

cat > "$BUILD_DIR/make_icon.swift" << 'EOF'
import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

let rect = CGRect(x: 64, y: 64, width: 896, height: 896)
let path = CGPath(roundedRect: rect, cornerWidth: 210, cornerHeight: 210, transform: nil)
ctx.addPath(path)
ctx.clip()

let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    CGColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1.0),
    CGColor(red: 0.09, green: 0.11, blue: 0.16, alpha: 1.0)
] as CFArray
if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    ctx.drawLinearGradient(grad, start: CGPoint(x: 512, y: 960), end: CGPoint(x: 512, y: 64), options: [])
}

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
ctx.setLineWidth(8)
ctx.addPath(path)
ctx.strokePath()

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.04))
ctx.setLineWidth(3)
for i in 1...4 {
    let y = CGFloat(140 + i * 150)
    ctx.move(to: CGPoint(x: 140, y: y))
    ctx.addLine(to: CGPoint(x: 884, y: y))
}
ctx.strokePath()

let points: [CGPoint] = [
    CGPoint(x: 170, y: 310),
    CGPoint(x: 310, y: 410),
    CGPoint(x: 430, y: 350),
    CGPoint(x: 575, y: 540),
    CGPoint(x: 690, y: 495),
    CGPoint(x: 845, y: 700)
]

ctx.saveGState()
let fillPath = CGMutablePath()
fillPath.move(to: points[0])
for pt in points.dropFirst() {
    fillPath.addLine(to: pt)
}
fillPath.addLine(to: CGPoint(x: 845, y: 180))
fillPath.addLine(to: CGPoint(x: 170, y: 180))
fillPath.closeSubpath()
ctx.addPath(fillPath)
ctx.clip()

let glowColors = [
    CGColor(red: 0.13, green: 0.84, blue: 0.48, alpha: 0.42),
    CGColor(red: 0.13, green: 0.84, blue: 0.48, alpha: 0.0)
] as CFArray
if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawLinearGradient(glowGrad, start: CGPoint(x: 512, y: 700), end: CGPoint(x: 512, y: 180), options: [])
}
ctx.restoreGState()

ctx.setStrokeColor(CGColor(red: 0.13, green: 0.84, blue: 0.48, alpha: 1.0))
ctx.setLineWidth(28)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.move(to: points[0])
for pt in points.dropFirst() {
    ctx.addLine(to: pt)
}
ctx.strokePath()

ctx.setFillColor(CGColor(red: 0.13, green: 0.84, blue: 0.48, alpha: 1.0))
ctx.fillEllipse(in: CGRect(x: 845 - 26, y: 700 - 26, width: 52, height: 52))

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
}
EOF

swiftc "$BUILD_DIR/make_icon.swift" -o "$BUILD_DIR/make_icon"
"$BUILD_DIR/make_icon" "$BUILD_DIR/icon_1024.png"

ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
for sz in 16 32 128 256 512; do
    sips -z $sz $sz "$BUILD_DIR/icon_1024.png" --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
    sz2=$((sz * 2))
    sips -z $sz2 $sz2 "$BUILD_DIR/icon_1024.png" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TickBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>app.tickbar.macos</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>TickBar</string>
    <key>CFBundleDisplayName</key>
    <string>TickBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 TickBar. Open Source under MIT License.</string>
</dict>
</plist>
EOF

echo "Compiling universal binary (arm64 + x86_64)..."
swiftc "$SCRIPT_DIR/Sources/TickBar.swift" \
    -O \
    -target arm64-apple-macosx13.0 \
    -o "$BUILD_DIR/TickBar-arm64"

swiftc "$SCRIPT_DIR/Sources/TickBar.swift" \
    -O \
    -target x86_64-apple-macosx13.0 \
    -o "$BUILD_DIR/TickBar-x86_64"

lipo -create -output "$APP_BUNDLE/Contents/MacOS/TickBar" \
    "$BUILD_DIR/TickBar-arm64" \
    "$BUILD_DIR/TickBar-x86_64"

xattr -cr "$APP_BUNDLE"
codesign --force --deep --sign - "$APP_BUNDLE"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -sf /Applications "$DMG_STAGING/Applications"

rm -f "$DMG_OUTPUT"
hdiutil create \
    -volname "TickBar" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT"

mkdir -p "$PROJECT_ROOT/downloads"
cp -f "$DMG_OUTPUT" "$PROJECT_ROOT/downloads/TickBar-macOS-Universal.dmg"

echo "Built DMG successfully at: $DMG_OUTPUT"
ls -lh "$DMG_OUTPUT"
