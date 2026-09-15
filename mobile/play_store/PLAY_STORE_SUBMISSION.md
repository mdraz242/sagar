# VyparHub Play Store Submission Notes

## Build Artifacts

- Android package: `com.vyparhub.mobile`
- Version: `1.0.0+1`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Release AAB: `build/app/outputs/bundle/release/app-release.aab`

## Store Listing URLs

- Privacy Policy: https://www.vyparhub.com/legal/privacy
- Public backend/API host: https://vyparhub.onrender.com
- Support email: use the active VyparHub support mailbox from the company website/app Help & Support screen.

## Data Safety Inputs

VyparHub collects and processes:

- Phone number for OTP login and account identity.
- Name, shop/business name, delivery address, city, pincode, and order details for B2B delivery.
- Device token for order and promotional push notifications.
- Analytics and crash data through Firebase Analytics and Crashlytics.
- OTP delivery metadata through MSG91.

Declare data sharing with:

- MSG91 for OTP SMS delivery.
- Firebase for analytics, crash reporting, and push notifications.
- Payment provider only when non-COD payment methods are activated.

## Pre-Submission Checklist

- Confirm Render backend is deployed and healthy.
- Confirm Supabase database migrations are applied.
- Confirm MSG91 OTP works on a real phone number.
- Confirm Firebase `google-services.json` package is `com.vyparhub.mobile`.
- Confirm app icon appears after uninstalling the old app and installing the fresh release.
- Upload the AAB to an internal testing track before production.
- Complete Play Console content rating, target audience, app access instructions, and Data Safety form.
