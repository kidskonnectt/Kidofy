# Deep Linking Setup Complete ✅

This document outlines the complete deep linking configuration for Kidofy app and website.

## What's Been Set Up

### 1. **Android App Links Configuration** (AndroidManifest.xml)
✅ Already configured in your app with:
- Package: `com.kidofy.kidsapp`
- Schemes: `https://kidofy.in` and `https://www.kidofy.in`
- Paths: `/channel` and `/snaps`
- Auto-verification enabled (`android:autoVerify="true"`)

### 2. **Domain Verification** (.well-known/assetlinks.json)
✅ File location: `KidofyMain/.well-known/assetlinks.json`
✅ Contains your app's certificate fingerprints
✅ Properly formatted with only `delegate_permission/common.handle_all_urls`

**Why this matters:** Google Play Console uses this file to verify that you own the domain and authorize your app to handle links from it.

### 3. **Website Deep Link Pages**

#### `/channel/index.html`
- **Purpose:** Handles channel-specific deep links
- **Supports:** 
  - `https://kidofy.in/channel/ChannelName`
  - `https://www.kidofy.in/channel/ChannelName`
  - `https://kidofy.in/channel?name=ChannelName`
- **Behavior:** 
  - Extracts channel name from URL
  - Attempts to open app via deep link
  - Shows fallback UI if app not installed
  - Links to Play Store

#### `/snaps/index.html`
- **Purpose:** Handles video/short deep links
- **Supports:**
  - `https://kidofy.in/snaps` (opens snaps feed)
  - `https://kidofy.in/snaps/VideoID`
  - `https://www.kidofy.in/snaps`
  - `https://www.kidofy.in/snaps?videoId=VideoID`
- **Behavior:**
  - Extracts video ID from URL (if provided)
  - Navigates to specific video or snaps feed
  - Shows Play Store fallback if needed

### 4. **Web Server Routing** (.htaccess)
✅ Updated to properly route:
- `/channel/*` - Serves `/channel/index.html`
- `/snaps/*` - Serves `/snaps/index.html`
- `.well-known/` - Directly accessible for assetlinks.json
- Other pages - Handler HTML extensions as before

## How Deep Linking Works

### Flow Diagram
```
User clicks link (e.g., https://www.kidofy.in/snaps/video123)
     ↓
Website page loads (snaps/index.html)
     ↓
JavaScript extracts video ID from URL
     ↓
Creates deep link: https://kidofy.in/snaps/video123
     ↓
[If app installed]
App receives deep link via Android App Links ✓
App navigates to requested content (snaps/video123)
     ↓
[If app NOT installed]
Falls back to Play Store link
```

## Testing the Setup

### 1. Test Website Pages Directly
```
https://www.kidofy.in/channel/Animals
https://www.kidofy.in/snaps/123abc
https://www.kidofy.in/snaps
```

### 2. Verify assetlinks.json
Visit: `https://www.kidofy.in/.well-known/assetlinks.json`

Should return valid JSON with your cert fingerprints.

### 3. Test Deep Linking (Android Device)
```bash
# Test channel deep link
adb shell am start -a android.intent.action.VIEW \
  -d "https://www.kidofy.in/channel/Animals" com.kidofy.kidsapp

# Test snaps deep link with specific video
adb shell am start -a android.intent.action.VIEW \
  -d "https://www.kidofy.in/snaps/video123" com.kidofy.kidsapp

# Test snaps without video ID
adb shell am start -a android.intent.action.VIEW \
  -d "https://www.kidofy.in/snaps" com.kidofy.kidsapp
```

### 4. Verify in Google Play Console
- Go to: App Configuration > App Links > Digital Asset Links
- Check domain status for:
  - `kidofy.in`
  - `www.kidofy.in`
- Status should change from "Pending verification" to "Verified" within 24 hours

## Deployment Checklist

- [ ] Upload `KidofyMain/` folder to your hosting provider
- [ ] Ensure `.well-known/assetlinks.json` is publicly accessible
- [ ] Verify `.htaccess` is properly deployed (if using Apache)
- [ ] Test website pages load correctly
- [ ] Test assetlinks.json is accessible
- [ ] Wait 24 hours for Google Play Console verification
- [ ] Test deep links on real Android device with app installed
- [ ] Re-upload APK/AAB to Google Play after domain verification
- [ ] Users updating app will get working deep links

## File Structure

```
KidofyMain/
├── .well-known/
│   └── assetlinks.json          ← CRITICAL: Domain verification file
├── .htaccess                     ← Updated routing rules
├── index.html                    ← Home page
├── channel/
│   └── index.html               ← Channel deep link handler
├── snaps/
│   └── index.html               ← Snaps deep link handler
├── assets/
├── css/
├── js/
└── ... (other pages)
```

## Important Notes

### Android App Links vs Deep Links
- **App Links (HTTPS):** Your app is the default handler - bypasses Chrome
- **Deep Links (Custom scheme):** User chooses between app and browser
- Our setup uses HTTPS App Links, which is better for user experience

### Certificate Fingerprints
The assetlinks.json file contains two fingerprints:
1. **Production release key** - for your production APK/AAB
2. **Debug key** - for testing during development

Make sure the production key matches your signed APK fingerprints in Play Console.

### Troubleshooting Domain Issues

**Problem:** Links still showing "Link not working" in Play Console
**Solution:**
1. Verify assetlinks.json is accessible at: `https://www.kidofy.in/.well-known/assetlinks.json`
2. Ensure file has valid JSON format
3. Certificate fingerprints in assetlinks.json must match your app's signing key
4. URL must be HTTPS
5. Wait 24 hours for Google's verification process
6. Re-submit APK to Play Console if already pending

**Problem:** App not opening when clicking links
**Solution:**
1. Ensure app is installed
2. Check AndroidManifest.xml intent-filters are correct
3. Verify app was built with the correct signing key
4. Check app's deep link handler (DeepLinkService) is implemented

## Next Steps (If Issues Persist)

1. **Get your signing key fingerprint:**
   ```bash
   # For release APK
   keytool -list -v -keystore your_keystore.jks
   
   # Or from your app directory in Play Console
   # Find your upload key/app signing key fingerprints
   ```

2. **Update assetlinks.json** with correct fingerprints if needed

3. **Re-upload your APK/AAB** to Google Play after verification

4. **Publish an update** so users get the new build

## Contact & Support

For issues with deep linking:
- Check Google Play Console > App configuration > App links
- Verify both `kidofy.in` and `www.kidofy.in` domains
- Ensure `.well-known/assetlinks.json` is accessible and valid JSON
- Check that AndroidManifest.xml has correct intent filters

---

**Last Updated:** February 22, 2026
**Status:** ✅ Complete & Ready for Deployment
