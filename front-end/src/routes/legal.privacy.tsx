import { createFileRoute } from "@tanstack/react-router";
import { LegalDoc } from "@/components/LegalDoc";

const MD = `# PRIVACY POLICY

**Last Updated: June 2026**

Welcome to VyparHub.

VyparHub Technologies Private Limited ("VyparHub", "Company", "we", "our", or "us") respects your privacy and is committed to protecting the information you share with us.

This Privacy Policy explains how we collect, use, process, store, protect, and disclose your information when you use the VyparHub website, mobile application, and related services (collectively referred to as the "Platform").

By accessing or using the Platform, you agree to the practices described in this Privacy Policy.

---

# 1. ABOUT VYPARHUB

VyparHub is a B2B commerce and technology platform that helps retailers discover trending products and connect with verified manufacturers, wholesalers, and suppliers across India.

Our platform focuses on empowering retailers, especially those located in Tier 2, Tier 3, Tier 4 cities and rural markets, by providing access to trending products, supplier networks, business insights, and efficient delivery services.

---

# 2. INFORMATION WE COLLECT

To provide our services effectively, we may collect the following information:

## Personal Information

* Full Name
* Mobile Number
* Email Address
* Shop Name
* Business Name
* GST Number
* PAN Number (where applicable)
* Business Address
* Delivery Address
* Billing Address

This information helps us verify users, process orders, deliver products, and comply with legal obligations.

---

## Account Information

When you create an account on VyparHub, we may collect:

* Username
* Password
* Business Category
* City
* District
* State
* Retailer or Manufacturer Information

This information helps us personalize your experience and provide relevant products and services.

---

## Transaction Information

When you place orders or interact with our platform, we may collect:

* Products Ordered
* Order Value
* Payment Information
* Delivery Information
* Return Requests
* Refund Requests
* Purchase History

This information is necessary to complete transactions and provide customer support.

---

## Device Information

We may automatically collect:

* Device Model
* Device Type
* Operating System
* Browser Information
* IP Address
* Network Information
* App Version

This information helps us improve security, prevent fraud, and optimize platform performance.

---

## Communication Information

We may collect information when you:

* Contact customer support
* Send emails
* Submit feedback
* Participate in surveys

This information helps us improve customer service and resolve issues efficiently.

---

# 3. HOW WE USE YOUR INFORMATION

We use information collected through the Platform for various business purposes including:

## Platform Operations

* Creating and managing user accounts
* Processing orders
* Managing deliveries
* Facilitating transactions
* Verifying businesses

---

## Customer Support

* Resolving complaints
* Handling refunds
* Managing returns
* Providing technical support

---

## Platform Improvement

* Improving search functionality
* Enhancing product discovery
* Optimizing delivery performance
* Improving user experience

---

## Security and Fraud Prevention

* Preventing unauthorized access
* Detecting suspicious activity
* Protecting user accounts
* Preventing fraudulent transactions

---

## Communication

We may send:

* Order confirmations
* Delivery updates
* Platform announcements
* Service notifications
* Policy updates

---

# 4. AI-POWERED PRODUCT RECOMMENDATIONS

VyparHub uses artificial intelligence, market analytics, and trend intelligence systems to help retailers discover trending products.

Our systems may analyze:

* Product demand patterns
* Regional trends
* Purchase behavior
* Retailer preferences
* Product popularity
* Market activity

These insights help retailers identify potentially high-demand products and assist manufacturers in understanding market opportunities.

However, these recommendations are informational only and do not guarantee sales, profits, or business outcomes.

---

# 5. APP PERMISSIONS

To provide certain features, VyparHub may request the following permissions:

## Location Permission

Location access helps us:

* Verify whether your address is serviceable
* Calculate delivery routes
* Provide accurate delivery estimates
* Show nearby suppliers
* Improve local product recommendations
* Optimize logistics operations

Users may disable location access, but some features may not function properly.

---

## Camera Permission

Camera access may be used for:

* Uploading product images
* Uploading GST or business documents
* Profile verification
* Reporting damaged products
* Reporting defective products
* Reporting expired products
* Reporting incorrect deliveries

VyparHub only accesses the camera when you choose to use camera-related features.

We do not access your camera in the background.

---

## Storage / Media Permission

Storage access helps users:

* Upload product images
* Upload verification documents
* Download invoices
* Download order reports
* Save product catalogs

VyparHub only accesses files that you voluntarily select.

---

## Phone Permission

Phone access may be used to:

* Contact customer support
* Contact delivery personnel
* Verify account ownership

VyparHub does not access your personal call records.

---

## Notification Permission

Notifications help us send:

* Order updates
* Delivery updates
* Refund updates
* Return updates
* Important account alerts

Users may disable notifications through device settings.

---

## SMS Permission (If Enabled)

SMS access may be used solely for:

* OTP verification
* Mobile number authentication
* Faster account registration

VyparHub does not read personal SMS messages unrelated to verification.

---

# 6. INFORMATION SHARING

We do not sell personal information.

We may share information with:

## Delivery Partners

To deliver products and provide delivery updates.

## Payment Providers

To securely process payments.

## Technology Service Providers

For hosting, analytics, customer support, and operational services.

## Government Authorities

Where disclosure is required by applicable laws, regulations, court orders, or legal processes.

---

# 7. DATA SECURITY

We use commercially reasonable security measures including:

* Secure servers
* Encryption technologies
* Authentication systems
* Access controls
* Security monitoring

While we take reasonable precautions, no method of transmission over the internet can be guaranteed to be completely secure.

---

# 8. COOKIES AND ANALYTICS

VyparHub may use cookies, analytics tools, and similar technologies to:

* Improve platform performance
* Remember user preferences
* Analyze user behavior
* Improve product recommendations
* Measure feature effectiveness

Users may control cookie settings through their browser preferences.

---

# 9. DATA RETENTION

We retain information only for as long as necessary to:

* Provide services
* Fulfill legal obligations
* Resolve disputes
* Prevent fraud
* Maintain business records

Certain information may be retained longer where required by law.

---

# 10. ACCOUNT DELETION

Users may request deletion of their account by contacting:

**[support@vyparhub.com](mailto:support@vyparhub.com)**

Upon receiving a valid request, we will review and process the request in accordance with applicable laws.

Certain records including invoices, transaction records, and tax-related information may be retained as required by law.

---

# 11. USER RIGHTS

Users may request:

* Access to their information
* Correction of inaccurate information
* Account deletion
* Withdrawal of certain permissions

Requests may be submitted through [support@vyparhub.com](mailto:support@vyparhub.com).

---

# 12. CHILDREN'S PRIVACY

VyparHub is intended for business users and individuals above 18 years of age.

We do not knowingly collect personal information from children.

---

# 13. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time.

Updated versions will be posted on the Platform along with the revised effective date.

Continued use of the Platform after updates constitutes acceptance of the revised Privacy Policy.

---

# 14. CONTACT US

**VyparHub Technologies Private Limited**

Website: https://www.vyparhub.com

Email: [support@vyparhub.com](mailto:support@vyparhub.com)

Phone: +91 8863923752

Location: Siwan, Bihar, India

---

# 15. GRIEVANCE OFFICER

For privacy-related concerns, complaints, or questions, please contact:

**Grievance Officer**

VyparHub Technologies Private Limited

Email: [support@vyparhub.com](mailto:support@vyparhub.com)

Phone: +91 8863923752

We aim to respond to valid complaints within 30 business days.
`;

export const Route = createFileRoute("/legal/privacy")({
  head: () => ({
    meta: [
      { title: "Privacy Policy — VyparHub" },
      { name: "description", content: "How VyparHub collects, uses, and protects your information." },
    ],
  }),
  component: () => <LegalDoc markdown={MD} />,
});
