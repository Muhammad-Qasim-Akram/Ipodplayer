# Production Build Setup & Guide

## Prerequisites

Before building a production APK, you need a **signing keystore**. Follow these steps:

### Step 1: Create a Keystore (One-time Setup)

Run this command in PowerShell from the project root:

```powershell
# Create a new keystore (replace paths and passwords as needed)
$keystorePath = "android/app/upload-keystore.jks"
$alias = "upload"

  # Change this!
$keyPassword = "your-key-password"      # Change this!

# Generate keystore (valid for 10000 days ~27 years)
keytool -genkey -v -keystore $keystorePath `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias $alias `
  -storepass $storePassword `
  -keypass $keyPassword `
  -dname "CN=Muhammad Qasim Akram, O=Personal, C=US"
```

**Important**: 
- Save the passwords somewhere safe
- The keystore file (`upload-keystore.jks`) should NOT be committed to git
- Losing the keystore means you cannot update the app on Google Play Store

### Step 2: Create key.properties File

Create `android/key.properties` with your keystore details:

```properties
storeFile=app/upload-keystore.jks
storePassword=your-store-password
keyAlias=upload
keyPassword=your-key-password
```

**Save this file!** But do NOT commit it to git (add to .gitignore).

### Step 3: Build Production APK

Once the keystore is set up, use the build scripts below.

---

## Production Build Scripts

### Option A: Simple PowerShell Script (Recommended)

Create a file: `scripts/build-production.ps1`

```powershell
# Production Build Script for Ipodplayer

param(
    [string]$BuildType = "apk",  # 'apk' or 'appbundle'
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "=========================================="
Write-Info "Ipodplayer Production Build"
Write-Info "=========================================="

# Step 1: Verify key.properties exists
Write-Info "`n[1/5] Checking keystore configuration..."
if (-not (Test-Path "android/key.properties")) {
    Write-Error "ERROR: android/key.properties not found!"
    Write-Error "Please create it with your keystore details (see README)"
    exit 1
}
Write-Success "✓ Keystore configured"

# Step 2: Get dependencies
Write-Info "`n[2/5] Fetching dependencies..."
flutter pub get --suppress-analytics
Write-Success "✓ Dependencies fetched"

# Step 3: Generate code (build_runner)
Write-Info "`n[3/5] Generating code (Hive adapters, etc)..."
flutter pub run build_runner build --delete-conflicting-outputs
Write-Success "✓ Code generated"

# Step 4: Run tests (optional)
if (-not $SkipTests) {
    Write-Info "`n[4/5] Running tests..."
    flutter test --no-pub --suppress-analytics
    Write-Success "✓ Tests passed"
} else {
    Write-Info "`n[4/5] Skipping tests"
}

# Step 5: Build release APK/AppBundle
Write-Info "`n[5/5] Building production $BuildType..."
Write-Info "Flavor: production | Mode: release"

if ($BuildType -eq "apk") {
    flutter build apk `
        --release `
        --no-pub `
        --suppress-analytics `
        --flavor production `
        -v
} elseif ($BuildType -eq "appbundle") {
    flutter build appbundle `
        --release `
        --no-pub `
        --suppress-analytics `
        --flavor production `
        -v
} else {
    Write-Error "Unknown build type: $BuildType (use 'apk' or 'appbundle')"
    exit 1
}

Write-Success "`n✓ Build complete!"

# Output paths
if ($BuildType -eq "apk") {
    Write-Info "`n=========================================="
    Write-Info "APK OUTPUT:"
    Write-Info "build/app/outputs/flutter-apk/app-production-release.apk"
    Write-Info "=========================================="
} else {
    Write-Info "`n=========================================="
    Write-Info "APP BUNDLE OUTPUT:"
    Write-Info "build/app/outputs/bundle/productionRelease/app-production-release.aab"
    Write-Info "=========================================="
}

Write-Success "`nReady to deploy! 🚀"
```

### Run the Production Build

```powershell
# Build production APK (for direct installation on your phone)
powershell -ExecutionPolicy Bypass -File scripts/build-production.ps1 -BuildType apk

# Or build App Bundle (for Google Play Store)
powershell -ExecutionPolicy Bypass -File scripts/build-production.ps1 -BuildType appbundle

# Skip tests for faster builds
powershell -ExecutionPolicy Bypass -File scripts/build-production.ps1 -BuildType apk -SkipTests
```

### Option B: Simple One-Liner

If you just want to build without the script:

```powershell
# Get dependencies and build production APK
flutter pub get --suppress-analytics ; `
flutter pub run build_runner build --delete-conflicting-outputs ; `
flutter build apk --release --no-pub --flavor production
```

---

## Installing on Your Phone

Once the APK is built:

```powershell
# Copy APK to phone (requires USB debugging enabled and ADB installed)
adb install build/app/outputs/flutter-apk/app-production-release.apk

# Or uninstall old version first, then install
adb uninstall com.adeeteya.classipod
adb install build/app/outputs/flutter-apk/app-production-release.apk
```

**On your Android phone:**
1. Enable USB Debugging (Settings → Developer Options → USB Debugging)
2. Connect via USB
3. Run the install command above

---

## Build Variants

### Production APK (For Your Phone)
```bash
flutter build apk --release --flavor production
```
- Output: `build/app/outputs/flutter-apk/app-production-release.apk`
- Package: `com.adeeteya.classipod`
- Optimized: Yes (tree-shaking, obfuscation)
- Signed: Yes (using keystore from key.properties)

### Production App Bundle (For Google Play Store)
```bash
flutter build appbundle --release --flavor production
```
- Output: `build/app/outputs/bundle/productionRelease/app-production-release.aab`
- Used by Play Store to generate optimized APKs for each device
- More efficient distribution than APK

---

## Troubleshooting

### "key.properties not found"
Create `android/key.properties` with keystore details (see Step 2 above)

### "Could not find keystore file"
Verify the path in key.properties is correct (e.g., `app/upload-keystore.jks`)

### "Signing certificate not recognized"
Your certificate was likely changed. Rebuild the app with fresh certificate or rotate it.

### "APK installation failed"
- Uninstall old version first: `adb uninstall com.adeeteya.classipod`
- Or use: `adb install -r` to replace without uninstalling

### Tests failing before build
Use `-SkipTests` flag: `powershell -File scripts/build-production.ps1 -SkipTests`

---

## Security Notes

⚠️ **Important:**
- Never commit `key.properties` to git
- Never share your keystore file or passwords
- Add to `.gitignore`:
  ```
  android/key.properties
  android/app/upload-keystore.jks
  ```
- Store keystore password in a safe place (not code!)

---

## Next Steps

1. ✅ Create keystore (Step 1)
2. ✅ Create key.properties (Step 2)
3. ✅ Run production build (Option A or B)
4. ✅ Install on phone via `adb install`

That's it! Your app will persist all Equalizer settings, lyrics, playlists, etc. across sessions. 🎵
