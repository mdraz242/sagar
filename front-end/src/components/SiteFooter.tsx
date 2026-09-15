import { Mail, Phone, Instagram, Linkedin, Facebook, Twitter } from "lucide-react";
import { Link } from "@tanstack/react-router";
import { useLang } from "@/i18n/LanguageContext";

export function SiteFooter() {
  const { t } = useLang();
  return (
    <footer id="contact" className="border-t border-border bg-foreground text-background">
      <div className="mx-auto grid max-w-7xl gap-10 px-4 py-14 sm:px-6 md:grid-cols-5 lg:px-8">
        <div className="md:col-span-2">
          <div className="flex items-center gap-3">
            <img src="/vyparhub-logo.svg" alt="VyparHub" className="h-10 w-auto" />
          </div>
          <p className="mt-4 max-w-md text-sm text-background/70">{t("footerTagline")}</p>
          <div className="mt-5 flex gap-3">
            {[Instagram, Linkedin, Facebook, Twitter].map((Icon, i) => (
              <a
                key={i}
                href="#social"
                className="grid h-9 w-9 place-items-center rounded-full border border-background/20 transition hover:border-orange hover:bg-orange"
                aria-label="social"
              >
                <Icon className="h-4 w-4" />
              </a>
            ))}
          </div>
        </div>
        <div>
          <h4 className="font-display text-sm font-bold uppercase tracking-wider text-background/60">{t("solutions")}</h4>
          <ul className="mt-4 space-y-2 text-sm">
            <li><Link to="/shop/fmcg" className="hover:text-orange">{t("fmcgMarketplace")}</Link></li>
            <li><Link to="/shop/fashion" className="hover:text-orange">{t("fashionMarketplace")}</Link></li>
            <li><a href="#paylater" className="hover:text-orange">{t("payLater")}</a></li>
            <li><a href="#about" className="hover:text-orange">{t("aiTrendAnalysis")}</a></li>
          </ul>
        </div>
        <div>
          <h4 className="font-display text-sm font-bold uppercase tracking-wider text-background/60">{t("legal")}</h4>
          <ul className="mt-4 space-y-2 text-sm">
            <li><a href="/legal/privacy" target="_blank" rel="noopener noreferrer" className="hover:text-orange">{t("privacy")}</a></li>
            <li><a href="/legal/terms" target="_blank" rel="noopener noreferrer" className="hover:text-orange">{t("terms")}</a></li>
            <li><a href="/legal/refund" target="_blank" rel="noopener noreferrer" className="hover:text-orange">{t("refund")}</a></li>
            <li><a href="/legal/seller-agreement" target="_blank" rel="noopener noreferrer" className="hover:text-orange">{t("sellerAgreement")}</a></li>
            <li><a href="/legal/account-deletion" target="_blank" rel="noopener noreferrer" className="hover:text-orange">{t("accountDeletion")}</a></li>
          </ul>
        </div>
        <div>
          <h4 className="font-display text-sm font-bold uppercase tracking-wider text-background/60">{t("support")}</h4>
          <ul className="mt-4 space-y-3 text-sm">
            <li className="flex items-center gap-2"><Mail className="h-4 w-4 text-orange" /> support@vyparhub.com</li>
            <li className="flex items-center gap-2"><Phone className="h-4 w-4 text-orange" /> +91 8863923752</li>
          </ul>
        </div>
      </div>

      <div className="border-t border-background/10">
        <div className="mx-auto max-w-7xl px-4 py-5 text-center sm:px-6 lg:px-8">
          <p className="font-display text-sm font-bold tracking-wide text-background sm:text-base">
            <span className="text-brand">Vypar</span><span className="text-orange">Hub</span> — <span className="text-orange">{t("discoverTrends")}</span>{" "}
            <span className="text-brand">{t("sourceSmarter")}</span>{" "}
            {t("growFaster")}
          </p>
        </div>
      </div>

      <div className="border-t border-background/10">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-2 px-4 py-5 text-xs text-background/60 sm:flex-row sm:px-6 lg:px-8">
          <p>© {new Date().getFullYear()} VyparHub. {t("allRights")}</p>
          <p>{t("madeInBharat")}</p>
        </div>
      </div>
    </footer>
  );
}
