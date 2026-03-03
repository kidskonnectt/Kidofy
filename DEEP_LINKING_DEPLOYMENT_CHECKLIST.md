# ✅ Deep Linking Deployment Checklist

Print this and check off as you complete each step!

---

## 📦 Pre-Deployment Verification

- [ ] Read `DEEP_LINKING_SETUP_SUMMARY.md` to understand what was done
- [ ] Read `DEEP_LINKING_DEPLOYMENT_QUICKSTART.md` for deployment steps
- [ ] Review `DEEP_LINKING_SETUP_COMPLETE.md` for technical details
- [ ] Have FTP/SSH access to your web hosting ready
- [ ] Have Google Play Console access ready

---

## 🚀 Deployment Phase 1: Upload Website Files

### File Preparation
- [ ] Locate the `KidofyMain` folder on your computer (in `g:\kidsapp\KidofyMain\`)
- [ ] Verify these NEW files exist:
  - [ ] `KidofyMain/channel/index.html` (for channel deep links)
  - [ ] `KidofyMain/snaps/index.html` (for snaps deep links)
  - [ ] `KidofyMain/deep-linking-test.html` (testing tool)
- [ ] Verify UPDATED files exist:
  - [ ] `KidofyMain/.htaccess` (routing rules)
  - [ ] `KidofyMain/.well-known/assetlinks.json` (domain verification)

### Uploading Files
- [ ] Connect to your web hosting via FTP or File Manager
- [ ] Navigate to the document root (usually `public_html` or `www`)
- [ ] Upload the entire `KidofyMain` folder (or merge with existing)
- [ ] Ensure the folder name is correct: `KidofyMain/` or configure as needed
- [ ] Verify folder structure on server:
  ```
  kidofy.in/
  ├── .well-known/assetlinks.json
  ├── channel/index.html
  ├── snaps/index.html
  ├── deep-linking-test.html
  ├── .htaccess
  └── ... (all other files)
  ```

---

## 🧪 Deployment Phase 2: Website Verification

### Test assetlinks.json
- [ ] Open browser and visit: `https://www.kidofy.in/.well-known/assetlinks.json`
- [ ] Expected: Valid JSON appears in browser
- [ ] NOT expected: 404 error
- [ ] If error: Check file exists on server and .well-known folder permissions

### Test Channel Page
- [ ] Visit: `https://www.kidofy.in/channel/Animals`
- [ ] Expected: Beautiful page loads with "Animals" channel name
- [ ] Expected: "Open in Kidofy" button visible
- [ ] NOT expected: 404 error
- [ ] If error: Check channel/ folder and index.html

### Test Snaps Pages
- [ ] Visit: `https://www.kidofy.in/snaps`
- [ ] Expected: Beautiful page loads with "Snaps Feed"
- [ ] Expected: "Open Snaps Feed" button visible
- [ ] NOT expected: 404 error

- [ ] Visit: `https://www.kidofy.in/snaps/video123`
- [ ] Expected: Page loads with video ID displayed
- [ ] Expected: "Watch in Kidofy App" button visible
- [ ] NOT expected: 404 error

### Test Verification Tool (Optional)
- [ ] Visit: `https://www.kidofy.in/deep-linking-test.html`
- [ ] Expected: Interactive testing page loads
- [ ] Click "Test assetlinks.json" button
- [ ] Expected: Shows "✓ assetlinks.json is accessible and valid!"
- [ ] If error: Debug using the tool's error message

---

## 🎮 Google Play Console Configuration

### Verify Domain Status
- [ ] Open Google Play Console
- [ ] Go to Your App > Configuration > App Links
- [ ] Look at the status for `kidofy.in`:
  - [ ] If "Pending verification": Wait up to 24 hours
  - [ ] If "Verified": Perfect! ✓
  - [ ] If "Failed": Check assetlinks.json error message
- [ ] Look at the status for `www.kidofy.in`:
  - [ ] If "Pending verification": Wait up to 24 hours
  - [ ] If "Verified": Perfect! ✓
  - [ ] If "Failed": Check assetlinks.json error message

### Handle Verification Issues
IF domains show "Failed" after 24 hours:
- [ ] Visit `https://https://developers.google.com/digital-asset-links/tools/generator`
- [ ] Enter your domain and app details
- [ ] Check if assetlinks.json is accessible
- [ ] Check if JSON format is valid
- [ ] Verify certificate fingerprints match your signing key
- [ ] Update assetlinks.json if fingerprints are wrong
- [ ] Re-test verification tool

---

## 📱 App Configuration Verification

### Check Android Manifest
- [ ] Open `android/app/src/main/AndroidManifest.xml`
- [ ] Verify this intent filter exists:
  ```xml
  <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      
      <data android:scheme="https" android:host="kidofy.in" android:pathPrefix="/channel" />
      <data android:scheme="https" android:host="www.kidofy.in" android:pathPrefix="/channel" />
      <data android:scheme="https" android:host="kidofy.in" android:pathPrefix="/snaps" />
      <data android:scheme="https" android:host="www.kidofy.in" android:pathPrefix="/snaps" />
  </intent-filter>
  ```
- [ ] If missing: Add it (already there for you ✓)

### Check Deep Link Service
- [ ] Open `lib/services/deep_link_service.dart`
- [ ] Verify it has implementations for:
  - [ ] `_handleUri()` method
  - [ ] `_handleHttpsContentLink()` method
  - [ ] Channel navigation logic
  - [ ] Snaps/video navigation logic
- [ ] If missing: Already implemented ✓

### Check App Dependencies
- [ ] Open `pubspec.yaml`
- [ ] Verify `app_links: ^6.4.1` is listed
- [ ] If missing: `flutter pub add app_links`

---

## 🔨 Build & Update App

### Build Release APK
- [ ] Open terminal in your project
- [ ] Run: `flutter build apk --release`
- [ ] Wait for build to complete
- [ ] Path: `build/app/outputs/flutter-app/release/app-release.apk`
- [ ] Or build AAB (recommended): `flutter build appbundle --release`

OR

### Build App Bundle (AAB) - Recommended
- [ ] Run: `flutter build appbundle --release`
- [ ] Wait for build to complete
- [ ] Path: `build/app/outputs/bundle/release/app-release.aab`

### Get Signing Key Fingerprint (For Reference)
- [ ] In terminal, run:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore
  # Password: android (for debug key)
  ```
- [ ] Or check in Google Play Console:
  - [ ] Go to Release > Setup > App signing
  - [ ] Copy the upload key SHA-256 fingerprint
- [ ] Compare with fingerprints in `assetlinks.json`
- [ ] If different: Update assetlinks.json with correct fingerprints

### Upload to Google Play Console
- [ ] Open Google Play Console
- [ ] Go to Your App > Testing > Internal testing (or Production)
- [ ] Click "Create new release"
- [ ] Upload your APK or AAB
- [ ] Review changes and publish
- [ ] Wait 2-3 hours for processing

---

## 🧬 Device Testing Phase

### Prepare Test Device
- [ ] Use Android device or emulator with Android 6.0+
- [ ] Ensure device has your app installed
- [ ] Uninstall old version if needed: `adb uninstall com.kidofy.kidsapp`
- [ ] Install from Play Store or sideload: `adb install app-release.apk`

### Test Method 1: Using ADB Commands
- [ ] Connect device via USB (or use emulator)
- [ ] Test channel deep link:
  ```bash
  adb shell am start -a android.intent.action.VIEW \
    -d "https://www.kidofy.in/channel/Animals" com.kidofy.kidsapp
  ```
  - [ ] Expected: App opens directly to Animals channel
  - [ ] NOT expected: Chrome opens first

- [ ] Test snaps feed:
  ```bash
  adb shell am start -a android.intent.action.VIEW \
    -d "https://www.kidofy.in/snaps" com.kidofy.kidsapp
  ```
  - [ ] Expected: App opens to Snaps feed

- [ ] Test snaps with specific video:
  ```bash
  adb shell am start -a android.intent.action.VIEW \
    -d "https://www.kidofy.in/snaps/myVideoID" com.kidofy.kidsapp
  ```
  - [ ] Expected: App opens with specific video

### Test Method 2: Using Browser
- [ ] On test device, open Chrome
- [ ] Visit: `https://www.kidofy.in/channel/Animals`
- [ ] Wait for page to load
- [ ] Expected: "Open with Kidofy?" prompt or automatic app open
- [ ] Tap "Open Kidofy"
- [ ] Expected: App opens with channel loaded

- [ ] Try: `https://www.kidofy.in/snaps`
- [ ] Expected: App opens to Snaps feed

### Test Method 3: Message App Test
- [ ] In Gmail, Messages, WhatsApp, etc.
- [ ] Send yourself a link: `https://www.kidofy.in/snaps/test123`
- [ ] Click the link
- [ ] Expected: App opens directly, not Chrome first

---

## ✅ Final Verification Checklist

### Website & Hosting
- [ ] All files uploaded successfully
- [ ] assetlinks.json accessible at correct URL
- [ ] Channel page loads without 404
- [ ] Snaps page loads without 404
- [ ] Test tool works and shows all checks passing

### Google Play Console
- [ ] Waited at least 24 hours since uploading website
- [ ] Both domains show "Verified" status
- [ ] No certificate errors or warnings
- [ ] App signing key fingerprints are correct

### App Functionality
- [ ] App builds successfully with no errors
- [ ] App signed with correct release key
- [ ] App uploaded to Play Store
- [ ] Play Store shows app is available (after 2-3 hours)

### Real Device Testing
- [ ] Installed app from Play Store or sideload
- [ ] ADB test 1 passed (channel): App opened directly
- [ ] ADB test 2 passed (snaps feed): App opened directly
- [ ] ADB test 3 passed (video): App opened with video
- [ ] Browser test passed: App opened from link
- [ ] Message app test passed: App opened from link

---

## 🎊 Success! You're Done!

If ALL checkboxes are ticked, your deep linking is fully functional!

### What This Means
✅ Users can click Kidofy links from anywhere  
✅ App opens directly without browser  
✅ Users navigate to correct content automatically  
✅ Non-installed users can install from Play Store  
✅ Seamless experience across all platforms  

---

## 🆘 If Something Isn't Working

### assetlinks.json Not Accessible
- [ ] Check file exists: `KidofyMain/.well-known/assetlinks.json`
- [ ] Check folder `.well-known` exists
- [ ] Verify file permissions (should be readable)
- [ ] Try clearing browser cache and retry
- [ ] Test from different browser/device

### Domains Still Pending After 24 Hours
- [ ] Visit `https://developers.google.com/digital-asset-links/tools/generator`
- [ ] Enter your domain information
- [ ] Tool will tell you what's wrong
- [ ] assetlinks.json might not be accessible or invalid JSON
- [ ] Certificate fingerprints might not match

### App Not Opening From Links
- [ ] Verify app is installed: `adb shell pm list packages | grep kidofy`
- [ ] Verify domain verification passed in Play Console
- [ ] Rebuild with correct signing key
- [ ] Check DeepLinkService is being called (add logs)
- [ ] Ensure app has internet permission in manifest

### Pages Show 404
- [ ] Check folders exist on server
- [ ] Check each has index.html
- [ ] Verify .htaccess is applied (if using Apache)
- [ ] Check file permissions
- [ ] If using Nginx, verify rewrite rules exist

---

## 📞 Need Help?

### For Website/Hosting Issues
- Contact your hosting provider
- Provide them: `assetlinks.json` file and where to place it
- Ask them to verify `.htaccess` is being applied

### For Google Play Issues
- Check Google Play Console > App Links section
- Look at the error message provided
- Use the Digital Asset Links verification tool
- Contact Google Play Console support if needed

### For App Issues
- Check DeepLinkService logs in Firebase Console
- Add console logs to see if deep link is being received
- Verify certificate fingerprints match
- Rebuild and re-upload to Play Console

---

**Date Completed:** ________________  
**Verified By:** ________________  
**Status:** ✅ FULL DEEP LINKING ENABLED

---

**Questions?** Refer to the documentation files:
- `DEEP_LINKING_SETUP_SUMMARY.md` - Overview
- `DEEP_LINKING_DEPLOYMENT_QUICKSTART.md` - Step-by-step
- `DEEP_LINKING_SETUP_COMPLETE.md` - Technical details
