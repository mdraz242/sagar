import { createFileRoute } from "@tanstack/react-router";
import { Package } from "lucide-react";
import { RetailerApplyForm } from "@/components/RetailerApplyForm";
import { useLang } from "@/i18n/LanguageContext";

export const Route = createFileRoute("/retailer/fmcg")({
  head: () => ({
    meta: [
      { title: "FMCG / Kirana Retailer Sign-up — VyparHub" },
      { name: "description", content: "Sign up as an FMCG & Kirana retailer on VyparHub." },
    ],
  }),
  component: Page,
});

function Page() {
  const { t } = useLang();
  return (
    <RetailerApplyForm
      category="retailer-fmcg"
      bgImage="/images/fmcg-shop-bg.jpg"
      accent="orange"
      Icon={Package}
      title={t("retailerFmcgTitle")}
      subtitle={t("retailerFormSub")}
    />
  );
}
