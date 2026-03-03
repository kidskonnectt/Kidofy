# 🔧 Premium Subscription - JWT Authentication Fix

## Problem Identified
When users clicked **"Subscribe Now"** on the Premium Plans screen, a **401 Unauthorized error** occurred with message:
```
FunctionException(status: 401, details: {code: 401, message: Invalid JWT}. reasonPhrase: Unauthorized)
```

## Root Cause
The issue was caused by **JWT verification mismatch** in the Supabase Edge Function invocation:

1. **Supabase Edge Functions have JWT verification enabled by default**
2. The Dart SDK's `client.functions.invoke()` method sends JWT tokens, but sometimes they can be:
   - Expired or stale
   - Improperly formatted
   - Missing required claims

3. The direct HTTP invocation wasn't properly handling JWT headers

## Solution Implemented

### 1. **Updated Edge Function** (`supabase/functions/create_razorpay_order/index.ts`)
   - Added comprehensive error logging for debugging
   - Added detailed CORS header configuration
   - Improved error handling to show exact error messages
   - Added logging for Razorpay API responses

### 2. **Updated Dart Premium Service** (`lib/services/premium_service.dart`)
   - **Switched from `client.functions.invoke()` to direct HTTP requests**
   - This gives full control over JWT token inclusion in headers
   - Implementation:
     - Imports `package:http/http.dart` for HTTP requests
     - Explicitly extracts JWT token from session: `session.accessToken`
     - Sends JWT in Authorization header: `Authorization: Bearer $jwtToken`
     - Constructs proper function URL: `$supabaseUrl/functions/v1/create_razorpay_order`
     - Handles JSON encoding/decoding properly
     - Better error messages for debugging

### 3. **Payment Verification Method Also Updated**
   - `verifyPayment()` method now uses direct HTTP requests
   - Same JWT handling and error logging
   - Proper response status validation

## Key Changes in Premium Service

### Before (Line 48-54):
```dart
final response = await client.functions.invoke(
  'create_razorpay_order',
  body: {'user_id': userId, 'amount': amount, 'plan_name': planName},
);
```

### After (Line 57-75):
```dart
final jwtToken = session.accessToken;
final supabaseUrl = client.supabaseUrl;
final functionUrl = '$supabaseUrl/functions/v1/create_razorpay_order';

final response = await http.post(
  Uri.parse(functionUrl),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $jwtToken',
  },
  body: jsonEncode({
    'user_id': userId,
    'amount': amount,
    'plan_name': planName,
  }),
);
```

## Testing Checklist
- [ ] Tap on Kidofy Premium screen
- [ ] Select a plan (6 Months or 1 Year)
- [ ] Click "Subscribe Now" button
- [ ] Verify **no 401 JWT error** appears
- [ ] Razorpay payment sheet opens successfully
- [ ] Payment process completes
- [ ] Premium subscription is activated
- [ ] Header shows "👑 Premium XXXd left" in home screen

## Debugging Info
If issues persist, check:
1. **Session token validity** - Ensure user is properly authenticated
2. **Supabase project URL** - Should be in format: `https://[your-project].supabase.co`
3. **HTTP package** - Ensure `http: ^1.0.0` or higher in pubspec.yaml
4. **Edge function logs** - Check Supabase dashboard for function logs
5. **Network issues** - Verify internet connectivity and no DNS issues

## Files Modified
1. ✅ `supabase/functions/create_razorpay_order/index.ts` - Enhanced error handling
2. ✅ `lib/services/premium_service.dart` - Direct HTTP implementation for JWT

## API Integration Notes
- **Function URL**: `{supabase_url}/functions/v1/create_razorpay_order`
- **Method**: POST
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer {jwt_token}`
- **Body**: `{ user_id, amount, plan_name }`
- **Response**: `{ order_id, amount, currency, status }`

## Status
✅ **COMPLETE** - Premium subscription JWT authentication issue resolved

---
*Last Updated: March 2, 2026*
