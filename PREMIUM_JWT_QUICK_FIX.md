# 🎯 Premium Subscription - 401 JWT Error Fix - QUICK REFERENCE

## The Issue
```
FunctionException(status: 401, details: {code: 401, message: Invalid JWT})
```
**When**: User clicks "Subscribe Now" on Premium screen
**Why**: JWT token validation failing in Supabase Edge Function

## The Fix (2 Files)

### 1️⃣ Edge Function: `supabase/functions/create_razorpay_order/index.ts`
**Change**: Added logging and better error handling
**Lines Changed**: 1-98 (entire file enhanced)
**What it does**: Provides detailed error messages and CORS handling

### 2️⃣ Premium Service: `lib/services/premium_service.dart`
**Change**: Replace SDK function invoke with direct HTTP request
**Key Line**:
```dart
// OLD (Line 48-54)
final response = await client.functions.invoke(
  'create_razorpay_order',
  body: {...},
);

// NEW (Line 57-75)
final jwtToken = session.accessToken;
final response = await http.post(
  Uri.parse('$supabaseUrl/functions/v1/create_razorpay_order'),
  headers: {
    'Authorization': 'Bearer $jwtToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({...}),
);
```

## Why This Works
- ✅ Direct HTTP gives full control over JWT token
- ✅ No SDK abstraction issues
- ✅ Explicit `Authorization: Bearer` header
- ✅ Better error messages for debugging
- ✅ Same pattern used in `verifyPayment()` method

## Deploy Now

```bash
# 1. Deploy edge function
supabase functions deploy create_razorpay_order

# 2. Rebuild app
flutter clean && flutter pub get && flutter run

# 3. Test
# - Open Premium screen
# - Click "Subscribe Now"
# - Should NOT see 401 error
# - Razorpay sheet opens normally
```

## Test Flow
```
User → Click "Subscribe Now"
    → Session refresh → JWT extracted
    → HTTP POST to Edge Function
    → Razorpay order created
    → Payment sheet opens
    → Payment completed
    → Subscription saved
    → "👑 Premium" shows in header ✅
```

## If It Fails
1. Check Supabase Edge Function logs
2. Verify user is authenticated
3. Ensure `http: ^1.6.0` in pubspec.yaml
4. Clear app cache: `flutter clean`
5. Check Supabase project URL is correct

## Files Changed Summary
- ✅ `lib/services/premium_service.dart` - HTTP implementation
- ✅ `supabase/functions/create_razorpay_order/index.ts` - Logging
- 📄 `PREMIUM_JWT_FIX_COMPLETE.md` - Full documentation
- 📄 `PREMIUM_JWT_DEPLOYMENT.md` - Deployment guide

---
**Status**: ✅ READY TO DEPLOY
**Risk Level**: 🟢 LOW (Non-breaking change)
**Rollback**: ✅ Simple (one git command)

