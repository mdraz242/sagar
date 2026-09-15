import { Link, useNavigate } from "@tanstack/react-router";
import { Menu, X, Globe, Smartphone, LogIn, Mail, Phone, Headphones } from "lucide-react";
import { useState, useEffect } from "react";
import { useLang } from "@/i18n/LanguageContext";

type ModalKind = null | "login" | "app" | "contact";

export function SiteHeader() {
  const [open, setOpen] = useState(false);
  const [modal, setModal] = useState<ModalKind>(null);
  const { lang, setLang, t } = useLang();
  const navigate = useNavigate();

  const toggleLang = () => setLang(lang === "EN" ? "HI" : "EN");

  useEffect(() => {
    const handler = (e: Event) => {
      const kind = (e as CustomEvent<ModalKind>).detail;
      if (kind) setModal(kind);
    };
    window.addEventListener("vh:open-modal", handler);
    return () => window.removeEventListener("vh:open-modal", handler);
  }, []);

  return (
    <>
      <header className="sticky top-0 z-50 w-full border-b border-border/60 bg-background/85 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-3 px-4 sm:px-6 lg:px-8">
          <Link to="/" className="flex shrink-0 items-center gap-2">
            <img src="/vyparhub-logo.svg" alt="VyparHub" className="h-9 w-auto" />
          </Link>
          <div className="hidden items-center gap-2 md:flex">
            <button
              onClick={toggleLang}
              className="inline-flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-2 text-xs font-bold text-foreground/80 transition hover:border-brand hover:text-brand"
              aria-label="Toggle language"
            >
              <Globe className="h-3.5 w-3.5" />
              {lang === "EN" ? "EN | हिं" : "हिं | EN"}
            </button>
            <button
              onClick={() => setModal("contact")}
              className="rounded-lg px-3 py-2 text-sm font-semibold text-foreground hover:bg-muted"
            >
              {t("contactUs")}
            </button>
            <button
              onClick={() => navigate({ to: "/manufacturer/fmcg" })}
              className="rounded-lg border border-brand/30 px-3 py-2 text-sm font-semibold text-brand hover:bg-brand/5"
            >
              {t("loginManufacturer")}
            </button>
            <button
              type="button"
              disabled
              aria-disabled="true"
              tabIndex={-1}
              className="pointer-events-none cursor-not-allowed rounded-lg bg-orange-gradient px-4 py-2 text-sm font-semibold text-orange-foreground opacity-60"
            >
              {t("downloadApp")}
            </button>
          </div>
          <button className="md:hidden" onClick={() => setOpen((o) => !o)} aria-label="menu">
            {open ? <X /> : <Menu />}
          </button>
        </div>
        {open && (
          <div className="border-t border-border bg-background md:hidden">
            <div className="mx-auto flex max-w-7xl flex-col gap-2 p-4">
              <button onClick={toggleLang} className="rounded-lg border px-3 py-2 text-center text-sm font-semibold">
                <Globe className="mr-1 inline h-4 w-4" /> {t("hindi")}
              </button>
              <button onClick={() => { setOpen(false); setModal("contact"); }} className="rounded-lg border px-3 py-2 text-center text-sm font-semibold">
                {t("contactUs")}
              </button>
              <button onClick={() => { setOpen(false); navigate({ to: "/manufacturer/fmcg" }); }} className="rounded-lg border border-brand/30 px-3 py-2 text-center text-sm font-semibold text-brand">
                {t("loginManufacturer")}
              </button>
              <button type="button" disabled aria-disabled="true" tabIndex={-1} className="pointer-events-none cursor-not-allowed rounded-lg bg-orange-gradient px-3 py-2 text-center text-sm font-semibold text-orange-foreground opacity-60">
                {t("downloadApp")}
              </button>
            </div>
          </div>
        )}
      </header>

      {modal && <ActionModal kind={modal} onClose={() => setModal(null)} />}
    </>
  );
}

function ActionModal({ kind, onClose }: { kind: Exclude<ModalKind, null>; onClose: () => void }) {
  const { t } = useLang();

  return (
    <div
      className="fixed inset-0 z-[100] grid place-items-center bg-black/60 p-4 backdrop-blur-sm animate-rise"
      onClick={onClose}
    >
      <div
        className="relative w-full max-w-md rounded-3xl border border-border bg-card p-7 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onClose}
          aria-label="Close"
          className="absolute right-4 top-4 grid h-8 w-8 place-items-center rounded-full bg-muted hover:bg-border"
        >
          <X className="h-4 w-4" />
        </button>

        {kind === "login" && (
          <>
            <div className="grid h-12 w-12 place-items-center rounded-xl bg-brand-gradient text-brand-foreground">
              <LogIn className="h-6 w-6" />
            </div>
            <h3 className="mt-4 font-display text-2xl font-black">{t("retailerLogin")}</h3>
            <p className="mt-1 text-sm text-muted-foreground">{t("retailerLoginSub")}</p>
            <form className="mt-5 space-y-3" onSubmit={(e) => e.preventDefault()}>
              <input
                type="tel"
                placeholder="+91 9999 99999"
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
              />
              <button className="w-full rounded-xl bg-brand-gradient py-3 text-sm font-bold text-brand-foreground shadow-glow">
                {t("sendOtp")}
              </button>
            </form>
          </>
        )}

        {kind === "app" && (
          <>
            <div className="grid h-12 w-12 place-items-center rounded-xl bg-brand-gradient text-brand-foreground">
              <Smartphone className="h-6 w-6" />
            </div>
            <h3 className="mt-4 font-display text-2xl font-black">Download VyparHub App</h3>
            <p className="mt-1 text-sm text-muted-foreground">2 ghante delivery, Pay Later, AI restock — sab mobile pe.</p>
            <div className="mt-5 grid grid-cols-2 gap-3">
              <a href="#" className="rounded-xl border border-border p-4 text-center transition hover:border-brand">
                <div className="text-xs text-muted-foreground">GET IT ON</div>
                <div className="font-display text-base font-black">Google Play</div>
              </a>
              <a href="#" className="rounded-xl border border-border p-4 text-center transition hover:border-brand">
                <div className="text-xs text-muted-foreground">DOWNLOAD ON</div>
                <div className="font-display text-base font-black">App Store</div>
              </a>
            </div>
            <div className="mt-5 rounded-xl bg-muted p-3 text-center text-xs text-muted-foreground">
              Ya SMS karein <b className="text-foreground">APP</b> to <b className="text-foreground">56161</b>
            </div>
          </>
        )}

        {kind === "contact" && (
          <>
            <div className="grid h-12 w-12 place-items-center rounded-xl bg-brand-gradient text-brand-foreground">
              <Headphones className="h-6 w-6" />
            </div>
            <h3 className="mt-4 font-display text-2xl font-black">{t("contactUs")}</h3>
            <p className="mt-1 text-sm text-muted-foreground">Humse seedha baat karein — email ya call par.</p>
            <div className="mt-5 grid gap-3">
              <a
                href="mailto:support@vyparhub.com"
                className="group flex items-center gap-4 rounded-2xl border-2 border-border bg-background p-4 text-left transition hover:border-brand hover:bg-brand/5"
              >
                <div className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-brand-gradient text-brand-foreground">
                  <Mail className="h-6 w-6" />
                </div>
                <div className="min-w-0">
                  <div className="font-display text-base font-black">Email</div>
                  <div className="mt-0.5 truncate text-xs text-muted-foreground">support@vyparhub.com</div>
                </div>
              </a>
              <a
                href="tel:+918863923752"
                className="group flex items-center gap-4 rounded-2xl border-2 border-border bg-background p-4 text-left transition hover:border-orange hover:bg-orange/5"
              >
                <div className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-orange-gradient text-orange-foreground">
                  <Phone className="h-6 w-6" />
                </div>
                <div className="min-w-0">
                  <div className="font-display text-base font-black">Phone</div>
                  <div className="mt-0.5 text-xs text-muted-foreground">+91 88639 23752</div>
                </div>
              </a>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
