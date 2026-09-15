import { Target, Telescope, Brain, Factory, Timer } from "lucide-react";
import { useLang } from "@/i18n/LanguageContext";

export function MissionVision() {
  const { t } = useLang();
  const stats = [
    { icon: Brain, key: "pillTrend" as const },
    { icon: Factory, key: "pillDirect" as const },
    { icon: Timer, key: "pill2Hr" as const },
  ];
  return (
    <section id="mission" className="relative overflow-hidden bg-foreground py-20 text-background sm:py-28">
      <div className="absolute inset-0 bg-[url('/images/hero-bg.jpg')] bg-cover bg-center opacity-10" />
      <div className="absolute inset-0 bg-gradient-to-br from-foreground via-foreground/95 to-brand/40" />
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <span className="text-xs font-bold uppercase tracking-[0.2em] text-orange">{t("whyExist")}</span>
          <h2 className="mt-3 font-display text-4xl font-black tracking-tight sm:text-5xl">
            {t("bharatRev1")} <span className="text-gradient-brand">{t("bharatRev2")}</span>
          </h2>
        </div>
        <div className="mt-14 grid gap-6 md:grid-cols-2">
          <div className="rounded-3xl border border-background/10 bg-background/5 p-8 backdrop-blur">
            <div className="grid h-12 w-12 place-items-center rounded-xl bg-brand-gradient">
              <Telescope className="h-6 w-6" />
            </div>
            <h3 className="mt-5 font-display text-2xl font-black">{t("ourVision")}</h3>
            <p className="mt-3 text-background/80">{t("visionBody")}</p>
          </div>
          <div className="rounded-3xl border border-background/10 bg-background/5 p-8 backdrop-blur">
            <div className="grid h-12 w-12 place-items-center rounded-xl bg-orange text-orange-foreground">
              <Target className="h-6 w-6" />
            </div>
            <h3 className="mt-5 font-display text-2xl font-black">{t("ourMission")}</h3>
            <p className="mt-3 text-background/80">{t("missionBody")}</p>
          </div>
        </div>

        <div className="mt-12 grid grid-cols-3 gap-4">
          {stats.map((s) => {
            const Icon = s.icon;
            return (
              <div
                key={s.key}
                className="flex flex-col items-center gap-3 rounded-2xl border border-background/10 bg-background/5 p-5 text-center"
              >
                <div className="grid h-10 w-10 place-items-center rounded-xl bg-orange/20 text-orange">
                  <Icon className="h-5 w-5" />
                </div>
                <div className="font-display text-sm font-black uppercase tracking-wider text-background">
                  {t(s.key)}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
