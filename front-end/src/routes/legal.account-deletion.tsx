import { createFileRoute } from "@tanstack/react-router";
import { LegalDoc } from "@/components/LegalDoc";

const MD = `# ACCOUNT DELETION

**Last Updated: August 2026**

Users may request deletion of their account by contacting:

**[support@vyparhub.com](mailto:support@vyparhub.com)**

Upon receiving a valid request, we will review and process the request in accordance with applicable laws.

Certain records including invoices, transaction records, and tax-related information may be retained as required by law.

---

## How to Delete Your Account (Step-by-Step)

* **Step 1:** Open the VyparHub app on your mobile device.
* **Step 2:** Go to **My Account**.
* **Step 3:** Tap on **Account Deletion**.
* **Step 4:** Review the information shown and click **Continue** to confirm your request.

Once submitted, our team will verify and process your request as per our Privacy Policy. Certain records such as invoices, transaction records, and tax-related information may be retained as required by applicable law.

If you face any issue while deleting your account, please reach out to us at [support@vyparhub.com](mailto:support@vyparhub.com) or call +91 8863923752.
`;

export const Route = createFileRoute("/legal/account-deletion")({
  head: () => ({
    meta: [
      { title: "Account Deletion — VyparHub" },
      { name: "description", content: "How to request deletion of your VyparHub account." },
    ],
  }),
  component: () => <LegalDoc markdown={MD} />,
});
