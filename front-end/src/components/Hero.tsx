import { ChainBackground } from "./ChainBackground";
import { ArrowRight, Zap, Factory } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { useLang } from "@/i18n/LanguageContext";
import { useNavigate } from "@tanstack/react-router";

function CountUp({ end, duration = 1600, className, suffix = "+" }: { end: number; duration?: number; className?: string; suffix?: string }) {
  const [value, setValue] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const started = useRef(false);
  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    const run = () => {
      if (started.current) return;
      started.current = true;
      const start = performance.now();
      const tick = (now: number) => {
        const p = Math.min(1, (now - start) / duration);
        const eased = 1 - Math.pow(1 - p, 3);
        setValue(Math.round(end * eased));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    };
    const io = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && run()),
      { threshold: 0.4 },
    );
    io.observe(node);
    return () => io.disconnect();
  }, [end, duration]);
  return <span ref={ref} className={className}>{value}{suffix}</span>;
}

export function Hero() {
  const { t } = useLang();
  const navigate = useNavigate();
  return (
    <section className="relative isolate overflow-hidden bg-gradient-to-b from-background via-background to-accent/30">
      <ChainBackground />
      <div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-brand/20 blur-3xl" />
      <div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-orange/20 blur-3xl" />

      <div className="relative mx-auto grid max-w-7xl items-start gap-12 px-4 pb-20 pt-4 sm:px-6 md:grid-cols-2 md:items-center md:pb-28 md:pt-6 lg:px-8">
        <div className="animate-rise">
          <span className="inline-flex items-center gap-2 rounded-full border border-brand/20 bg-brand/5 px-3 py-1 text-xs font-semibold text-brand">
            <Zap className="h-3.5 w-3.5" /> {t("heroBadge")}
          </span>
          <h1 className="mt-5 font-display text-5xl font-black leading-[1.05] tracking-tight sm:text-6xl lg:text-7xl">
            {t("heroTitle1")}
            <span className="block text-gradient-brand">{t("heroTitle2")}</span>
          </h1>
          <p className="mt-5 font-display text-2xl font-bold tracking-tight text-orange sm:text-3xl">
            {t("heroSubtitle")}
          </p>
          <p className="mt-6 max-w-xl text-base leading-relaxed text-muted-foreground sm:text-lg">
            {t("heroDesc")}
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <button
              onClick={() => navigate({ to: "/retailer/fmcg" })}
              className="group inline-flex items-center gap-2 rounded-xl bg-brand-gradient px-6 py-3 text-sm font-bold text-brand-foreground shadow-glow transition hover:scale-[1.02]"
            >
              <Factory className="h-4 w-4" />
              {t("loginRetailer")}
              <ArrowRight className="h-4 w-4 transition group-hover:translate-x-1" />
            </button>
            <button
              type="button"
              disabled
              aria-disabled="true"
              tabIndex={-1}
              className="pointer-events-none inline-flex cursor-not-allowed items-center gap-2 rounded-xl border border-border bg-background/70 px-6 py-3 text-sm font-bold opacity-60 backdrop-blur"
            >
              {t("downloadApp")}
            </button>
          </div>
          <div className="mt-8 flex flex-wrap items-center gap-6 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <Zap className="h-5 w-5 text-orange" />
              <span><b className="text-foreground">{t("twoHourLabel")}</b> {t("twoHourFmcg")}</span>
            </div>
            <div className="flex items-center gap-2">
              <Zap className="h-5 w-5 text-brand" />
              <span>Fastest delivery done by <b className="text-foreground">10 Min</b></span>
            </div>
          </div>

          <div className="mt-6 grid max-w-2xl grid-cols-3 gap-3 sm:grid-cols-5">
            <div className="rounded-xl border border-border bg-background/70 p-3 text-center backdrop-blur">
              <CountUp end={500} className="font-display text-2xl font-black text-gradient-brand sm:text-3xl" />
              <div className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">{t("skus")}</div>
            </div>
            <div className="rounded-xl border border-border bg-background/70 p-3 text-center backdrop-blur">
              <CountUp end={20000} className="font-display text-2xl font-black text-orange sm:text-3xl" />
              <div className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">{t("retailers")}</div>
            </div>
            <div className="rounded-xl border border-border bg-background/70 p-3 text-center backdrop-blur">
              <CountUp end={5000} className="font-display text-2xl font-black text-brand sm:text-3xl" />
              <div className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Villages</div>
            </div>
            <div className="rounded-xl border border-border bg-background/70 p-3 text-center backdrop-blur">
              <CountUp end={3} className="font-display text-2xl font-black text-orange sm:text-3xl" />
              <div className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Districts</div>
            </div>
            <div className="rounded-xl border border-border bg-background/70 p-3 text-center backdrop-blur">
              <CountUp end={2} suffix="" className="font-display text-2xl font-black text-orange sm:text-3xl" />
              <div className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Hours</div>
            </div>
          </div>
        </div>

        <div className="relative flex h-[560px] flex-col items-center justify-center gap-5 sm:h-[640px] lg:h-[700px]">
          <div className="inline-block rounded-2xl bg-gradient-to-r from-[#003399] to-[#FF6600] px-6 py-3 text-center shadow-glow">
            <span className="font-display text-lg font-black uppercase tracking-wide text-white sm:text-2xl">
              Vypar Badhao, Munafa Kamao
            </span>
          </div>
          <div className="relative w-[280px] animate-float sm:w-[320px]">
            <div className="absolute inset-x-8 -bottom-6 h-14 rounded-full bg-brand/30 blur-2xl" />
            <div className="relative rounded-[2.5rem] border-[10px] border-neutral-900 bg-neutral-900 shadow-[0_30px_60px_rgba(0,0,0,0.3)]">
              <div className="absolute left-1/2 top-0 z-10 h-5 w-28 -translate-x-1/2 rounded-b-2xl bg-neutral-900" />
              <img
                src="/images/vyparhub-app-screenshot.jpg"
                alt="VyparHub FMCG app screenshot"
                className="aspect-[9/20] w-full rounded-[2rem] object-cover"
              />
            </div>
            <span className="absolute left-1/2 top-4 -translate-x-1/2 rounded-full bg-brand px-3 py-1 text-[11px] font-bold text-brand-foreground shadow-lg">
              FMCG • 2 HR
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}
