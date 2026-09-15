import { createFileRoute } from "@tanstack/react-router";
import { LegalDoc } from "@/components/LegalDoc";

const MD = `# REFUND & RETURNS POLICY

**Last Updated: June 2026**

Welcome to VyparHub.

This Refund & Returns Policy explains how cancellations, returns, replacements, shortages, damaged products, defective products, expired products, incorrect deliveries, and refunds are handled on the VyparHub platform.

By placing an order through VyparHub, you agree to this Refund & Returns Policy.

---

# 1. ABOUT THIS POLICY

VyparHub is a B2B platform serving retailers, wholesalers, distributors, and manufacturers.

Since most transactions involve business purchases and wholesale quantities, returns are governed by the rules described below.

Retailers are strongly advised to inspect products carefully at the time of delivery.

---

# 2. ORDER CANCELLATION

## Cancellation Before Dispatch

Retailers may request cancellation of an order before the order has been dispatched for delivery.

Cancellation requests can be submitted through:

* The VyparHub Platform
* Customer Support
* Official Support Channels

If the order has not been dispatched, cancellation may be approved.

---

## Cancellation After Dispatch

Once an order has been dispatched from the fulfillment location or delivery route has started, cancellation may not be possible.

This is particularly applicable for:

* Express Delivery Orders
* Same-Day Delivery Orders
* Perishable or time-sensitive products

---

## Cancellation by VyparHub

VyparHub reserves the right to cancel an order due to:

* Product unavailability
* Inventory mismatch
* Pricing errors
* Technical errors
* Fraud concerns
* Regulatory requirements
* Violation of platform policies

If payment has already been made, an eligible refund will be initiated.

---

# 3. DELIVERY INSPECTION REQUIREMENT

Retailers must inspect all products immediately upon delivery.

Inspection should include:

* Product quantity
* Product quality
* Packaging condition
* Product expiry
* Product correctness
* Visible damage

Our delivery partner will provide reasonable time for inspection during delivery.

---

# 4. ELIGIBLE RETURN CONDITIONS

Returns may only be accepted at the time of delivery under the following circumstances:

## Damaged Products

Products that are visibly damaged during transportation or delivery.

Examples:

* Torn packaging
* Broken products
* Leaking products
* Crushed cartons

---

## Defective Products

Products that contain manufacturing defects or are not functioning as intended.

---

## Expired Products

Products found to be expired at the time of delivery.

---

## Incorrect Products Delivered

Products that differ from what was ordered.

Examples:

* Wrong brand
* Wrong SKU
* Wrong size
* Wrong variant
* Wrong quantity pack

---

## Quantity Shortage

Where delivered quantity is less than the quantity invoiced or ordered.

---

# 5. NON-RETURNABLE ITEMS

Returns will NOT be accepted for:

* Change of mind
* Slow-moving inventory
* Product not selling
* Price changes after purchase
* Customer ordering mistakes
* Market demand fluctuations
* Return requests raised after delivery acceptance

Once delivery is accepted, products become non-returnable except where required by applicable law.

---

# 6. ACCEPTANCE OF DELIVERY

Delivery acceptance means:

* Products have been inspected.
* Products have been received in satisfactory condition.
* Retailer accepts quantity and quality.

After delivery acceptance:

* No return request may be entertained.
* No replacement request may be entertained.
* No shortage claim may be entertained.

Except where otherwise required by law.

---

# 7. RETURN PROCESS

If an eligible issue is identified during delivery:

### Step 1

Inform the delivery agent immediately.

### Step 2

Show the issue to the delivery agent.

### Step 3

Provide photographs or evidence if requested.

### Step 4

The affected products may be returned immediately.

### Step 5

The issue will be recorded in the system for verification and resolution.

---

# 8. REFUND METHODS

Approved refunds may be processed through:

## Original Payment Method

Online payments may be refunded back to the original payment source.

---

## Bank Transfer

Refunds may be transferred directly to the retailer's bank account.

---

## Platform Credit

Refunds may be provided as VyparHub platform credit where agreed by the retailer.

---

# 9. REFUND TIMELINE

Once a refund is approved:

* Refund processing may begin within 7 business days.
* Actual credit timing depends on the bank, payment provider, or financial institution.

VyparHub is not responsible for delays caused by banking systems or third-party payment processors.

---

# 10. CASH ON DELIVERY ORDERS

For Cash on Delivery (COD) orders:

* Eligible refunds may be processed through bank transfer, UPI, or platform credit.
* Retailers may be required to provide payment details for refund processing.

---

# 11. FRAUDULENT CLAIMS

VyparHub reserves the right to reject any claim that appears:

* False
* Misleading
* Fraudulent
* Unsupported by evidence

Repeated abuse of refund policies may result in account suspension or termination.

---

# 12. LIMITATION OF LIABILITY

VyparHub's liability in relation to returns and refunds shall not exceed the purchase value of the affected products.

VyparHub shall not be responsible for:

* Lost business opportunities
* Lost profits
* Inventory losses
* Indirect damages

---

# 13. CHANGES TO THIS POLICY

VyparHub may update this Refund & Returns Policy from time to time.

Updated versions will be posted on the Platform with a revised effective date.

Continued use of the Platform constitutes acceptance of such updates.

---

# 14. CONTACT US

**VyparHub Technologies Private Limited**

Website: https://www.vyparhub.com

Email: [support@vyparhub.com](mailto:support@vyparhub.com)

Phone: +91 8863923752

Location: Siwan, Bihar, India
`;

export const Route = createFileRoute("/legal/refund")({
  head: () => ({
    meta: [
      { title: "Refund & Returns Policy — VyparHub" },
      { name: "description", content: "How VyparHub handles cancellations, returns, and refunds." },
    ],
  }),
  component: () => <LegalDoc markdown={MD} />,
});
