# Play Store Data Safety Draft

Use this as the source checklist when filling the Google Play Console Data safety form.

## Data Collected

- Personal info: name, phone number.
- Business/shop info: shop name, shop address, area, city, state, pincode.
- App activity: cart contents, order history, order status, order notes.
- Financial info: payment amount, payment mode, payment status, payment provider reference.
- Device or other IDs: Firebase Cloud Messaging token.
- Diagnostics: crash logs through Firebase Crashlytics.
- Analytics: app interaction analytics through Firebase Analytics.

## Data Not Collected By VyparHub

- Card number.
- CVV.
- UPI PIN.
- Net banking password.

These payment details are handled by Razorpay, not stored by VyparHub.

## Data Sharing

Data is shared with third parties only to provide app functionality:

- Razorpay: payment processing and payment status.
- Firebase: analytics, crash reporting, and push notifications.
- SMS/OTP provider such as MSG91: phone verification messages.
- Hosting/database providers: API hosting, storage, and database operations.

## Purpose

- Account management.
- Authentication and OTP verification.
- Order placement and delivery coordination.
- Payment processing.
- Fraud prevention and service security.
- Notifications for order updates and promotions.
- Analytics and crash diagnostics.

## Encryption

- Data is encrypted in transit using HTTPS in production.
- Passwords are stored as secure password hashes.
- JWT authentication protects private API routes.

## User Control and Deletion

Users can request correction or deletion of account information by contacting support.
Some order and payment metadata may be retained where required for accounting,
legal compliance, dispute resolution, and fraud prevention.

## Production Checklist Before Submission

- Replace `support@vyparhub.example` with the real support email.
- Publish `docs/privacy-policy.html`.
- Add the live privacy policy URL to `PRIVACY_POLICY_URL.md`.
- Confirm Razorpay, Firebase, and SMS provider names match the production setup.
