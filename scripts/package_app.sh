#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/package_app.sh [version] [output_dir] [bin_dir]
VERSION="${1:-0.1.1}"
VERSION="${VERSION#v}" # Strip leading v if present
OUTPUT_DIR="${2:-dist}"
BIN_DIR="${3:-$(swift build -c release --show-bin-path)}"

export COPYFILE_DISABLE=1

echo "=== Packaging MacOSGamingApp.app Bundle (v${VERSION}) ==="
echo "Binary directory: ${BIN_DIR}"
echo "Output directory: ${OUTPUT_DIR}"

if [ ! -x "${BIN_DIR}/MacOSGamingApp" ]; then
    echo "MacOSGamingApp executable not found in ${BIN_DIR}. Building release target..."
    swift build --product MacOSGamingApp -c release
    BIN_DIR="$(swift build -c release --show-bin-path)"
fi

mkdir -p "${OUTPUT_DIR}"
APP_DIR="${OUTPUT_DIR}/MacOSGamingApp.app"

# Clean any existing bundle in output directory
rm -rf "${APP_DIR}"

# 1. Create standard macOS .app bundle directory hierarchy
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 2. Copy binary into Contents/MacOS/ and ensure executable permissions
cp "${BIN_DIR}/MacOSGamingApp" "${APP_DIR}/Contents/MacOS/MacOSGamingApp"
chmod +x "${APP_DIR}/Contents/MacOS/MacOSGamingApp"

# 3. Create Info.plist with complete macOS application metadata
cat << EOF > "${APP_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>MacOSGaming</string>
    <key>CFBundleExecutable</key>
    <string>MacOSGamingApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.macosgaming.MacOSGamingApp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacOSGamingApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Clean AppleDouble files if present on volume
find "${APP_DIR}" -name "._*" -delete 2>/dev/null || true

# Validate plist syntax using macOS plutil
plutil -lint "${APP_DIR}/Contents/Info.plist"

# 4. Create zip archive containing the .app bundle
ZIP_NAME="MacOSGamingApp-v${VERSION}-macos-arm64.zip"
echo "Compressing into ${OUTPUT_DIR}/${ZIP_NAME}..."
(
    cd "${OUTPUT_DIR}"
    rm -f "${ZIP_NAME}"
    zip -r -y "${ZIP_NAME}" "MacOSGamingApp.app" > /dev/null
)

echo "=== MacOSGamingApp.app Bundle Package Completed Successfully ==="
ls -lh "${OUTPUT_DIR}/${ZIP_NAME}"
