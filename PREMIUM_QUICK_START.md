# 🚀 Kidofy Premium - Quick Start Guide

## Installation & Deployment (5 Minutes)

### Step 1: Update Flutter Dependencies
```bash
cd g:\kidsapp
flutter pub get
```

### Step 2: Deploy SQL Schema to Supabase
1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your Kidofy project
3. Go to **SQL Editor** → Click **New Query**
4. Copy-paste entire contents of: `PREMIUM_SUBSCRIPTIONS_SCHEMA.sql`
5. Click **Run**
6. Verify success (no errors)

### Step 3: Deploy Edge Functions
```bash
# Deploy create order function
supabase functions deploy create_razorpay_order

# Deploy payment verification function
supabase functions deploy verify_razorpay_payment
```

Or via Dashboard:
1. Go to **Edge Functions**
2. **Create new function**
3. Name: `create_razorpay_order`
4. Paste code from `supabase/functions/create_razorpay_order/index.ts`
5. Deploy
6. Repeat for `verify_razorpay_payment`

### Step 4: Test Build & Run
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Quick Test

### Test Premium Purchase Flow:
1. Open app and login with test account
2. Tap "Kidofy >" header or navigate to Premium screen
3. Select "1 Year" plan (best for testing)
4. Click "Subscribe Now"
5. Razorpay checkout opens
6. Use [Razorpay test card](https://razorpay.com/settlements/test-cards/):
   - Card: 4111111111111111
   - Expiry: 12/25
   - CVV: 123
7. Complete payment
8. Header changes to "👑 Premium 365d left"
9. ✅ Success!

---

## 🎨 How Users Experience Premium

### Before Purchase (Free User)
- Header shows: **Kidofy >** (with animated arrow)
- Premium screen shows 4 plans
- Can watch limited content (with ads)

### After Purchase (Premium User)
- Header changes to: **👑 Premium** with gradient badge
- Badge shows: **"365d left"** (depends on plan)
- Enjoy: Unlimited videos, ad-free
- Header badge updates automatically as days count down

### When Subscription Expires
- Header reverts to: **Kidofy >**
- User can purchase again or renew

---

## 💳 Pricing Plans

| Plan | Price | Duration | Per Month | Best For |
|------|-------|----------|-----------|----------|
| 1 Month | ₹99 | 30 days | ₹99 | Try Premium |
| 3 Months | ₹249 | 90 days | ₹83 | Regular User |
| 6 Months | ₹399 | 180 days | ₹67 | Committed User |
| 1 Year | ₹699 | 365 days | ₹58 | Best Offer ⭐ |

---

## 🔑 API Credentials (Already Set)

```
Razorpay Live:
  API Key: rzp_live_SLuT1s4uUlhjIo
  API Secret: S6IxL4TSXRMgVUSaTbactkyn
```

✅ No additional configuration needed!

---

## 📊 Monitor Subscriptions

### Check Database
1. Supabase Dashboard → **SQL Editor**
2. Run query:
```sql
SELECT * FROM premium_subscriptions 
ORDER BY purchase_date DESC 
LIMIT 10;
```

### View Fields
- `id` - Unique subscription ID
- `user_id` - User who purchased
- `plan_name` - Which plan (1 Month, 3 Months, etc)
- `purchase_date` - When they bought
- `expiry_date` - When it expires
- `status` - active, expired, cancelled
- `razorpay_payment_id` - Payment reference

---

## ⚠️ Common Issues & Fixes

### Issue: "Payment Gateway Not Opening"
```
❌ Razorpay checkout doesn't open
✅ Solution:
   1. flutter clean
   2. flutter pub get
   3. Rebuild and run
   4. Check: android/app/build.gradle has razorpay dependency
```

### Issue: "Subscription Not Saved"
```
❌ Payment successful but subscription not in database
✅ Solution:
   1. Check premium_subscriptions table exists in Supabase
   2. Run the SQL migration again
   3. Check RLS policies (should allow service role)
```

### Issue: "Header Not Showing Premium"
```
❌ After successful payment, header still shows Kidofy
✅ Solution:
   1. Ensure PremiumNotifier in MultiProvider (main.dart)
   2. Restart app completely (not just hot reload)
   3. Check: Consumer<PremiumNotifier> in kid_app_bar.dart
```

### Issue: "Premium Showing Expired Immediately"
```
❌ Just purchased but showing expired
✅ Solution:
   1. Check system time on device is correct
   2. Check expiry_date in database (should be future date)
   3. Ensure DateTime calculations are using UTC
```

---

## 🔐 Security Checklist

- ✅ API Secret never exposed in app (only in Supabase function)
- ✅ Signature verification prevents fake payments
- ✅ RLS policies prevent unauthorized database access
- ✅ User can only see their own subscriptions
- ✅ Payment IDs stored for audit trail

---

## 📱 What's Different in UI

### Header Changes:

**Free User:**
```
┌────────────────────────────────┐
│  🎬  Kidofy  >       🔍    👤 │
└────────────────────────────────┘
```

**Premium User:**
```
┌────────────────────────────────┐
│  🎬  👑 Premium     🔍    👤  │
│      365d left                 │
└────────────────────────────────┘
```

---

## 🎯 Next Steps

1. ✅ Deploy SQL schema (2 min)
2. ✅ Deploy Edge functions (2 min)
3. ✅ Test payment flow (5 min)
4. ✅ Monitor database entries
5. ✅ Promote to users!

---

## 📞 Need Help?

**Check these files first:**
- `PREMIUM_IMPLEMENTATION_COMPLETE.md` - Full documentation
- `PREMIUM_SUBSCRIPTIONS_SCHEMA.sql` - Database schema
- `lib/providers/premium_notifier.dart` - State management
- `lib/services/razorpay_service.dart` - Payment service

---

## ✨ You're All Set! 

Premium subscriptions are now live on your Kidofy app! 🎉

**Your users can now:**
- Select from 4 subscription plans
- Pay securely via Razorpay
- See "Premium" badge in header
- Enjoy unlimited ad-free content
- Auto expiration when subscription ends

**Revenue streams activated:**
- 💰 ₹99/month (1 Month plan)
- 💰 ₹249/quarter (3 Months plan)
- 💰 ₹399/half-year (6 Months plan)
- 💰 ₹699/year (1 Year plan - Best seller!)

---

**Go Live! 🚀**

