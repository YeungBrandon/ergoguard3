#!/bin/bash
# ============================================================
#  ErgoGuard HK AI - macOS/Linux Setup Script
#  Run this ONCE from inside the ergoguard_hk folder
#  Usage: bash setup_mac_linux.sh
# ============================================================

set -e

echo ""
echo " ============================================="
echo "  ErgoGuard HK AI - Project Setup"
echo " ============================================="
echo ""

# Step 1: Check Flutter
if ! command -v flutter &>/dev/null; then
    echo "[ERROR] Flutter not found. Install from: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo "[OK] Flutter found: $(flutter --version 2>&1 | head -1)"

# Step 2: Backup source
echo ""
echo "[1/5] Backing up source files..."
mkdir -p _backup
cp -r lib _backup/lib
cp pubspec.yaml _backup/pubspec.yaml
cp README.md _backup/README.md 2>/dev/null || true
echo "[OK] Source files backed up"

# Step 3: Generate fresh Android scaffolding
echo ""
echo "[2/5] Generating Android project structure..."
cd ..
flutter create --org com.ergoguard --project-name ergoguard_hk --platforms android --no-pub ergoguard_hk_temp > /dev/null 2>&1

# Copy android/ folder
cp -r ergoguard_hk_temp/android/. ergoguard_hk/android/

# Clean up
rm -rf ergoguard_hk_temp
cd ergoguard_hk
echo "[OK] Android structure generated"

# Step 4: Restore source
echo ""
echo "[3/5] Restoring ErgoGuard source files..."
rm -rf lib
cp -r _backup/lib lib
cp _backup/pubspec.yaml pubspec.yaml
rm -rf _backup
echo "[OK] Source files restored"

# Step 5: Patch minSdk to 24
echo ""
echo "[4/5] Patching minSdk to 24 (required for ML Kit)..."
sed -i.bak 's/minSdk flutter\.minSdkVersion/minSdk 24/g' android/app/build.gradle
sed -i.bak 's/minSdkVersion flutter\.minSdkVersion/minSdkVersion 24/g' android/app/build.gradle
rm -f android/app/build.gradle.bak
echo "[OK] minSdk patched"

# Step 6: flutter pub get
echo ""
echo "[5/5] Installing dependencies..."
flutter pub get

echo ""
echo " ============================================="
echo "  Setup complete!"
echo " ============================================="
echo ""
echo " Next steps:"
echo "   1. Connect your Android phone via USB"
echo "   2. Enable USB Debugging on the phone"
echo "   3. Run:  flutter run"
echo ""
