import { createFileRoute } from "@tanstack/react-router";
import { LegalDoc } from "@/components/LegalDoc";

const MD = `# TERMS OF SERVICE

**Last Updated: June 2026**

Welcome to VyparHub.

These Terms of Service ("Terms") govern your access to and use of the VyparHub website, mobile application, products, services, and related features (collectively referred to as the "Platform").

The Platform is operated by **VyparHub Technologies Private Limited** ("VyparHub", "Company", "we", "our", or "us").

By accessing, registering, or using the Platform, you agree to be bound by these Terms. If you do not agree with these Terms, you must not use the Platform.

---

# 1. ABOUT VYPARHUB

VyparHub is a B2B technology-enabled commerce platform that connects retailers, wholesalers, distributors, and manufacturers across India.

Our mission is to help retailers discover trending products, access reliable suppliers, and grow their businesses through technology, logistics support, and market intelligence.

VyparHub may provide:

* Product discovery
* Manufacturer sourcing
* Retailer onboarding
* Order management
* Logistics support
* Market insights
* AI-powered product recommendations

---

# 2. ELIGIBILITY

To use VyparHub, you must:

* Be at least 18 years old.
* Be legally capable of entering into binding contracts.
* Provide accurate business information.
* Comply with all applicable laws and regulations.

VyparHub reserves the right to reject or terminate accounts that provide false or misleading information.

---

# 3. ACCOUNT REGISTRATION

Users may be required to create an account to access certain services.

During registration, users must provide accurate information including:

* Name
* Mobile Number
* Business Details
* Shop Information
* GST Details (where applicable)

Users are responsible for maintaining the confidentiality of their account credentials.

Any activity conducted through your account shall be considered your responsibility.

---

# 4. BUSINESS VERIFICATION

VyparHub may require additional verification before granting access to certain features.

Verification may include:

* GST Verification
* PAN Verification
* Shop Verification
* Business Registration Documents
* Identity Verification

VyparHub reserves the right to approve, reject, suspend, or revoke verification status at its sole discretion.

---

# 5. PRODUCT LISTINGS

Manufacturers and suppliers are responsible for:

* Product descriptions
* Product images
* Product specifications
* Pricing accuracy
* Inventory information

VyparHub does not guarantee that all product information provided by sellers will always be complete or error-free.

Users should independently evaluate products before purchasing.

---

# 6. AI-POWERED RECOMMENDATIONS

VyparHub may provide AI-powered recommendations and trend insights based on:

* Market demand
* Regional preferences
* Product performance
* Platform activity
* Retailer behavior

These recommendations are intended to support business decisions.

VyparHub does not guarantee:

* Product sales
* Revenue generation
* Business growth
* Inventory turnover

Users remain solely responsible for their purchasing and business decisions.

---

# 7. ORDERS

When an order is placed through the Platform:

* The order is subject to acceptance and availability.
* Prices may change before confirmation.
* VyparHub may refuse or cancel orders where necessary.

Orders may be cancelled due to:

* Product unavailability
* Pricing errors
* Technical issues
* Fraud concerns
* Policy violations

---

# 8. PAYMENTS

VyparHub may support:

### Cash on Delivery (COD)

Retailers may pay at the time of delivery where available.

### Online Payments

Payments may be processed through authorized payment service providers.

### Pay Later Services

Pay Later facilities may be introduced in the future and may require additional eligibility checks, verification, credit assessments, and approval.

Approval for such services shall be entirely at VyparHub's discretion.

---

# 9. DELIVERY SERVICES

VyparHub currently offers:

## Express Delivery

Eligible orders may be delivered within approximately 2 hours.

Delivery timelines are estimates and may vary due to:

* Traffic conditions
* Weather conditions
* Product availability
* Operational constraints

---

## Next-Day Delivery

Orders may also be scheduled for next-day morning delivery.

Delivery schedules may vary depending on service availability and operational requirements.

---

# 10. RETURNS AND REFUNDS

Products sold through VyparHub are generally non-returnable after delivery acceptance.

Retailers must inspect products at the time of delivery.

Returns may only be accepted for:

* Damaged products
* Defective products
* Expired products
* Incorrect products delivered
* Quantity shortages

Any such issue must be reported immediately during delivery.

Once the retailer accepts delivery, the order shall be deemed successfully completed.

---

# 11. PROHIBITED ACTIVITIES

Users must not:

* Submit false information.
* Engage in fraud.
* Manipulate prices.
* Upload unlawful content.
* Interfere with platform operations.
* Attempt unauthorized access.
* Use automated tools without permission.
* Violate applicable laws.

Violation of these Terms may result in immediate suspension or termination.

---

# 12. INTELLECTUAL PROPERTY

All rights relating to:

* VyparHub branding
* Logos
* Software
* Designs
* Graphics
* Content
* Technology

remain the exclusive property of VyparHub Technologies Private Limited.

Users may not copy, distribute, modify, reproduce, or commercially exploit platform content without prior written consent.

---

# 13. THIRD-PARTY SERVICES

The Platform may integrate with third-party services including:

* Payment gateways
* Logistics providers
* Communication tools
* Analytics providers

VyparHub is not responsible for the actions, content, or policies of third-party providers.

---

# 14. ACCOUNT SUSPENSION AND TERMINATION

VyparHub may suspend or terminate accounts for:

* Fraudulent activity
* Repeated policy violations
* Misuse of services
* Submission of false information
* Harmful conduct toward users or the Platform

Suspension may occur without prior notice where required for security or compliance purposes.

---

# 15. DISCLAIMER OF WARRANTIES

The Platform is provided on an "as available" and "as is" basis.

VyparHub does not guarantee:

* Uninterrupted operation
* Error-free services
* Continuous availability
* Specific business outcomes

Users assume responsibility for their use of the Platform.

---

# 16. LIMITATION OF LIABILITY

To the maximum extent permitted by law, VyparHub shall not be liable for:

* Indirect damages
* Consequential damages
* Lost profits
* Business interruption
* Data loss

Our total liability shall not exceed the value of the affected transaction.

---

# 17. CHANGES TO THESE TERMS

VyparHub may modify these Terms from time to time.

Updated versions will be posted on the Platform.

Continued use of the Platform constitutes acceptance of revised Terms.

---

# 18. GOVERNING LAW

These Terms shall be governed by and interpreted in accordance with the laws of India.

Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts located in Bihar, India.

---

# 19. CONTACT INFORMATION

**VyparHub Technologies Private Limited**

Website: https://www.vyparhub.com

Email: [support@vyparhub.com](mailto:support@vyparhub.com)

Phone: +91 8863923752

Location: Siwan, Bihar, India
`;

export const Route = createFileRoute("/legal/terms")({
  head: () => ({
    meta: [
      { title: "Terms of Service — VyparHub" },
      { name: "description", content: "VyparHub Terms of Service." },
    ],
  }),
  component: () => <LegalDoc markdown={MD} />,
});
