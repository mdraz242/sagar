import { createFileRoute } from "@tanstack/react-router";
import { Hero } from "@/components/Hero";

import { AllInOne } from "@/components/AllInOne";
import { BiharFocus } from "@/components/BiharFocus";
import { ShopCategoriesPreview } from "@/components/ShopCategoriesPreview";
import { MissionVision } from "@/components/MissionVision";
import { Feedback } from "@/components/Feedback";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "VyparHub — India's #1 B2B Commerce Platform" },
      { name: "description", content: "Discover trending products, source directly from verified manufacturers, and grow your retail business with AI-powered market insights. FMCG & Fashion for Bharat's retailers." },
      { property: "og:title", content: "VyparHub — India's #1 B2B Commerce Platform" },
      { property: "og:description", content: "Discover trending products, source directly from verified manufacturers, and grow your retail business with AI-powered market insights." },
    ],
  }),
  component: Index,
});

function Index() {
  return (
    <div className="min-h-screen bg-background">
      <SiteHeader />
      <main>
        <Hero />
        
        <AllInOne />
        <BiharFocus />
        <ShopCategoriesPreview />
        <MissionVision />
        <Feedback />
      </main>
      <SiteFooter />
    </div>
  );
}
