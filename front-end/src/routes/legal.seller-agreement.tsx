import { createFileRoute } from "@tanstack/react-router";
import { LegalDoc } from "@/components/LegalDoc";

const MD = `# SELLER / MANUFACTURER AGREEMENT

**Last Updated: June 2026**

This Seller / Manufacturer Agreement ("Agreement") governs the participation of manufacturers, suppliers, wholesalers, distributors, and brand owners ("Seller", "Manufacturer", "Supplier", "You") on the VyparHub Platform.

By registering, listing products, or conducting business on VyparHub, you agree to comply with this Agreement.

---

# 1. ABOUT VYPARHUB

VyparHub Technologies Private Limited ("VyparHub", "Company", "we", "our", "us") operates a B2B marketplace platform that connects retailers with manufacturers, wholesalers, suppliers, and distributors across India.

VyparHub provides technology infrastructure, product discovery tools, logistics support, and AI-powered market insights to facilitate transactions between businesses.

Unless expressly stated otherwise, VyparHub acts as a technology platform and is not the manufacturer of products listed on the Platform.

---

# 2. SELLER ELIGIBILITY

To sell products through VyparHub, sellers must:

* Be legally authorized to conduct business.
* Possess required licenses and registrations.
* Provide accurate business information.
* Comply with all applicable laws and regulations.

VyparHub may request:

* GST Registration
* PAN Details
* Business Registration Documents
* Brand Authorization Letters
* Bank Account Details
* Identity Verification Documents

Failure to provide accurate information may result in rejection or suspension.

---

# 3. PRODUCT LISTINGS

Sellers are responsible for maintaining accurate product listings.

All listings must contain:

* Product Name
* Product Images
* Product Description
* Product Specifications
* Product Pricing
* Available Inventory
* Expiry Information (where applicable)

Sellers must ensure that all information is accurate, complete, and regularly updated.

---

# 4. PRODUCT QUALITY RESPONSIBILITY

The Seller is solely responsible for:

* Product quality
* Product safety
* Product authenticity
* Product packaging
* Product labeling
* Product compliance

Sellers must ensure that products meet all applicable regulatory and safety requirements.

VyparHub shall not be responsible for manufacturing defects or quality issues originating from the Seller.

---

# 5. PROHIBITED PRODUCTS

The following products may not be listed:

* Counterfeit goods
* Stolen goods
* Illegal products
* Expired products
* Restricted products prohibited by law
* Products violating intellectual property rights

VyparHub reserves the right to remove such listings without notice.

---

# 6. INVENTORY MANAGEMENT

Sellers are responsible for:

* Maintaining accurate stock levels
* Updating inventory regularly
* Avoiding overselling
* Ensuring product availability

Repeated inventory failures may result in penalties or suspension.

---

# 7. ORDER FULFILLMENT

Upon receiving a confirmed order, sellers agree to:

* Prepare orders promptly
* Maintain product quality
* Package products appropriately
* Meet dispatch requirements

Failure to fulfill orders may affect seller performance ratings.

---

# 8. PRICING RESPONSIBILITY

Sellers are solely responsible for:

* Product pricing
* Discounts
* Offers
* Promotional pricing

Prices displayed must be accurate and free from misleading information.

VyparHub may suspend listings containing obvious pricing errors.

---

# 9. RETURNS AND CLAIMS

If a retailer reports:

* Damaged products
* Defective products
* Expired products
* Incorrect products
* Quantity shortages

The Seller may be required to cooperate with VyparHub during investigation and resolution.

VyparHub reserves the right to recover losses arising from verified seller-related issues.

---

# 10. DELIVERY AND LOGISTICS

VyparHub may provide delivery support and logistics services.

Sellers agree to:

* Hand over products in saleable condition.
* Ensure correct packaging.
* Follow dispatch timelines.

Delivery support by VyparHub does not transfer responsibility for product quality to VyparHub.

---

# 11. AI INSIGHTS AND TREND RECOMMENDATIONS

VyparHub may provide trend reports, product recommendations, and market insights using AI-powered systems.

Such insights are intended for informational purposes only.

VyparHub does not guarantee:

* Sales volume
* Revenue growth
* Product demand
* Market performance

Business decisions remain the responsibility of the Seller.

---

# 12. INTELLECTUAL PROPERTY

Sellers represent and warrant that:

* They own or are authorized to use all trademarks, logos, images, and content uploaded.
* Their listings do not infringe third-party intellectual property rights.

The Seller shall indemnify VyparHub against claims arising from intellectual property violations.

---

# 13. COMPLIANCE WITH LAWS

Sellers agree to comply with:

* GST regulations
* Consumer protection laws
* Product safety regulations
* Packaging and labeling requirements
* Tax laws
* Applicable Indian laws

Failure to comply may result in suspension or termination.

---

# 14. ACCOUNT SUSPENSION

VyparHub may suspend or terminate seller accounts for:

* Fraudulent activities
* Counterfeit products
* Repeated customer complaints
* Policy violations
* Misleading listings
* Regulatory violations

Suspension may occur without prior notice where necessary.

---

# 15. LIMITATION OF LIABILITY

VyparHub acts as a technology platform facilitating transactions.

To the maximum extent permitted by law, VyparHub shall not be liable for:

* Loss of profits
* Business interruption
* Indirect damages
* Consequential damages

The Seller remains responsible for products listed and sold through the Platform.

---

# 16. INDEMNIFICATION

The Seller agrees to indemnify and hold harmless VyparHub, its directors, officers, employees, and affiliates against claims, damages, losses, liabilities, and expenses arising from:

* Product defects
* Regulatory violations
* Intellectual property infringement
* Seller misconduct
* Breach of this Agreement

---

# 17. CHANGES TO THIS AGREEMENT

VyparHub may modify this Agreement from time to time.

Updated versions will be posted on the Platform.

Continued use of the Platform constitutes acceptance of the revised Agreement.

---

# 18. GOVERNING LAW

This Agreement shall be governed by the laws of India.

Any dispute arising from this Agreement shall be subject to the exclusive jurisdiction of the courts located in Bihar, India.

---

# 19. CONTACT INFORMATION

**VyparHub Technologies Private Limited**

Website: https://www.vyparhub.com

Email: [support@vyparhub.com](mailto:support@vyparhub.com)

Phone: +91 8863923752

Location: Siwan, Bihar, India
`;

export const Route = createFileRoute("/legal/seller-agreement")({
  head: () => ({
    meta: [
      { title: "Seller / Manufacturer Agreement — VyparHub" },
      { name: "description", content: "Terms for manufacturers and suppliers selling on VyparHub." },
    ],
  }),
  component: () => <LegalDoc markdown={MD} />,
});
