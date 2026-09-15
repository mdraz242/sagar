import { createFileRoute } from "@tanstack/react-router";
import { Shirt } from "lucide-react";
import { RetailerApplyForm } from "@/components/RetailerApplyForm";
import { useLang } from "@/i18n/LanguageContext";

export const Route = createFileRoute("/retailer/fashion")({
  head: () => ({
    meta: [
      { title: "Fashion / Beauty Retailer Sign-up — VyparHub" },
      { name: "description", content: "Sign up as a fashion & beauty retailer on VyparHub." },
    ],
  }),
  component: Page,
});

function Page() {
  const { t } = useLang();
  return (
    <RetailerApplyForm
      category="retailer-fashion"
      bgImage="/images/fashion-shop-bg.jpg"
      accent="brand"
      Icon={Shirt}
      title={t("retailerFashionTitle")}
      subtitle={t("retailerFormSub")}
    />
  );
}
