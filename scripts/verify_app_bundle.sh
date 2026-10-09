#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/verify_app_bundle.sh [path/to/MacOSGamingApp.app]
APP_PATH="${1:-dist/MacOSGamingApp.app}"

echo "=== Verifying macOS App Bundle Structure: ${APP_PATH} ==="

if [ ! -d "${APP_PATH}" ]; then
    echo "ERROR: Directory ${APP_PATH} does not exist!"
    exit 1
fi

if [ ! -d "${APP_PATH}/Contents" ]; then
    echo "ERROR: ${APP_PATH}/Contents directory missing!"
    exit 1
fi

if [ ! -d "${APP_PATH}/Contents/MacOS" ]; then
    echo "ERROR: ${APP_PATH}/Contents/MacOS directory missing!"
    exit 1
fi

if [ ! -x "${APP_PATH}/Contents/MacOS/MacOSGamingApp" ]; then
    echo "ERROR: ${APP_PATH}/Contents/MacOS/MacOSGamingApp executable missing or not executable!"
    exit 1
fi

if [ ! -f "${APP_PATH}/Contents/Info.plist" ]; then
    echo "ERROR: ${APP_PATH}/Contents/Info.plist missing!"
    exit 1
fi

echo "Validating Info.plist syntax..."
plutil -lint "${APP_PATH}/Contents/Info.plist"

PACKAGE_TYPE=$(plutil -extract CFBundlePackageType raw "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "")
if [ "${PACKAGE_TYPE}" != "APPL" ]; then
    echo "ERROR: CFBundlePackageType is '${PACKAGE_TYPE}', expected 'APPL'!"
    exit 1
fi

EXECUTABLE_NAME=$(plutil -extract CFBundleExecutable raw "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "")
if [ "${EXECUTABLE_NAME}" != "MacOSGamingApp" ]; then
    echo "ERROR: CFBundleExecutable is '${EXECUTABLE_NAME}', expected 'MacOSGamingApp'!"
    exit 1
fi

BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "")
if [ -z "${BUNDLE_ID}" ]; then
    echo "ERROR: CFBundleIdentifier is missing!"
    exit 1
fi

echo "App Bundle Details:"
echo "  - Package Type: ${PACKAGE_TYPE}"
echo "  - Executable:   ${EXECUTABLE_NAME}"
echo "  - Bundle ID:    ${BUNDLE_ID}"
echo "=== All App Bundle Validations Passed Successfully! ==="
