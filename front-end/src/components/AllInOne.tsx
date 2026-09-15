import { Link } from "@tanstack/react-router";
import { Sparkles, ArrowRight, ShoppingBasket, Factory } from "lucide-react";
import { useLang, T as TDict } from "@/i18n/LanguageContext";

type TKey = keyof typeof TDict;

type Row = {
  tag: string;
  tagKey?: TKey;
  tagIcon: React.ComponentType<{ className?: string }>;
  accent: "brand" | "orange";
  titleKey: TKey;
  bubble: string;
  bodyKey: TKey;
  cta: { labelKey: TKey; href: string };
  ctaDisabled?: boolean;
  image: string;
  alt: string;
  bubbleSide: "left" | "right";
};

const rows: Row[] = [
  {
    tag: "FMCG",
    tagIcon: ShoppingBasket,
    accent: "brand",
    titleKey: "rowFmcgTitle",
    bubble:
      "Bhaiya, AI bata raha hai is hafte aapke gaon mein namkeen aur cold drink sabse zyada bik rahi hai — abhi restock kar lo, 2 ghante mein deliver ho jayegi.",
    bodyKey: "rowFmcgBody",
    cta: { labelKey: "browseFmcg", href: "/shop/fmcg" },
    ctaDisabled: true,
    image: "/images/retailer-kirana-1.jpg",
    alt: "Village kirana shop owner using VyparHub",
    bubbleSide: "right",
  },
  {
    tag: "For Manufacturers",
    tagKey: "rowMfgTag",
    tagIcon: Factory,
    accent: "orange",
    titleKey: "rowMfgTitle",
    bubble:
      "Real-time demand data Tier 2, 3, 4 cities aur villages se. Apna FMCG brand seedha har dukaan tak — bina distributor, bina markup.",
    bodyKey: "rowMfgBody",
    cta: { labelKey: "becomePartner", href: "/manufacturer/fmcg" },
    image: "/images/manufacturer-fmcg-products.jpg",
    alt: "Real FMCG products — atta, oil, sugar, besan, rajma, salt and more",
    bubbleSide: "left",
  },
];

export function AllInOne() {
  const { t } = useLang();
  return (
    <section
      id="about"
      className="relative overflow-hidden border-y border-border bg-muted/40 py-16 sm:py-24"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-3xl text-center">
          <span className="inline-flex items-center gap-1.5 rounded-full border border-orange/30 bg-orange/10 px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-orange">
            <Sparkles className="h-3.5 w-3.5" /> {t("aiTrendingPill")}
          </span>
          <h2 className="mt-3 font-display text-3xl font-black tracking-tight sm:text-4xl">
            {t("everythingIn")} <span className="text-gradient-brand">{t("onePlatform")}</span>
          </h2>
          <p className="mt-2 text-sm text-muted-foreground sm:text-base">
            FMCG aur Manufacturers — Bharat ka pura B2B chain ek hi app mein.
            AI batayega aapke ilaake mein abhi kya trending hai.
          </p>
        </div>

        <div className="mt-14 space-y-14 sm:space-y-20">
          {rows.map((row, i) => {
            const Icon = row.tagIcon;
            const reversed = row.bubbleSide === "left";
            const accentText = row.accent === "brand" ? "text-brand" : "text-orange";
            const accentBg =
              row.accent === "brand"
                ? "bg-brand/10 border-brand/20"
                : "bg-orange/10 border-orange/20";
            return (
              <div
                key={row.titleKey}
                className={`grid items-center gap-8 md:grid-cols-5 md:gap-10 ${
                  reversed ? "md:[&>div:first-child]:order-2" : ""
                }`}
              >
                <div className="relative md:col-span-2">
                  <div className="overflow-hidden rounded-3xl border border-border bg-card shadow-glow">
                    <img
                      src={row.image}
                      alt={row.alt}
                      loading="lazy"
                      width={1400}
                      height={1050}
                      className="aspect-square h-full w-full object-cover"
                    />
                  </div>
                  <div
                    className={`absolute ${
                      row.bubbleSide === "right"
                        ? "-right-3 sm:-right-6"
                        : "-left-3 sm:-left-6"
                    } -bottom-5 max-w-[88%] rounded-2xl border ${accentBg} bg-background/95 p-3 shadow-xl backdrop-blur sm:max-w-xs`}
                  >
                    <div className="flex items-start gap-2">
                      <Sparkles className={`mt-0.5 h-4 w-4 shrink-0 ${accentText}`} />
                      <p className="text-[11px] font-medium leading-relaxed text-foreground sm:text-xs">
                        {row.bubble}
                      </p>
                    </div>
                    <div
                      className={`absolute ${
                        row.bubbleSide === "right" ? "left-6" : "right-6"
                      } -top-2 h-4 w-4 rotate-45 border-l border-t ${accentBg} bg-background`}
                    />
                  </div>
                </div>

                <div className="md:col-span-3">
                  <span
                    className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-bold uppercase tracking-wider ${accentBg} ${accentText}`}
                  >
                    <Icon className="h-3.5 w-3.5" /> {row.tagKey ? t(row.tagKey) : row.tag}
                  </span>
                  <h3 className="mt-3 font-display text-2xl font-black tracking-tight sm:text-3xl">
                    {t(row.titleKey)}
                  </h3>
                  <p className="mt-3 text-sm text-muted-foreground sm:text-base">
                    {t(row.bodyKey)}
                  </p>
                  {row.ctaDisabled ? (
                    <span
                      aria-disabled="true"
                      className={`mt-5 inline-flex cursor-not-allowed items-center gap-1.5 text-sm font-bold opacity-60 ${accentText}`}
                    >
                      {t(row.cta.labelKey)} <ArrowRight className="h-4 w-4" />
                    </span>
                  ) : (
                    <Link
                      to={row.cta.href}
                      className={`mt-5 inline-flex items-center gap-1.5 text-sm font-bold ${accentText}`}
                    >
                      {t(row.cta.labelKey)} <ArrowRight className="h-4 w-4" />
                    </Link>
                  )}
                </div>

                <div className="hidden" aria-hidden>
                  {i}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
