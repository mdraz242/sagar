import { MapPin } from "lucide-react";
import indiaMap from "@/data/india-map.json";

const BIHAR_ID = "br";

// Bihar's centroid on the map viewBox (612x696) — used to anchor the pin + callout.
const BIHAR_LABEL = { x: 369, y: 275 };

export function IndiaMapHero() {
  return (
    <div className="relative w-full max-w-md overflow-hidden rounded-3xl border border-border bg-card shadow-glow">
      {/* Header */}
      <div className="px-5 pt-5">
        <p className="font-display text-lg font-black leading-tight tracking-tight sm:text-xl">
          We're live in <span className="text-orange">BIHAR</span>!
        </p>
        <p className="mt-1 flex items-center gap-1 text-xs font-semibold text-muted-foreground">
          <MapPin className="h-3.5 w-3.5 shrink-0 text-orange" />
          Starting here, expanding across all of India.
        </p>
      </div>

      {/* Map */}
      <div className="relative px-3 pb-3 pt-2">
        <svg
          viewBox={indiaMap.viewBox}
          className="h-auto w-full"
          role="img"
          aria-label="Map of India with Bihar highlighted"
        >
          {indiaMap.locations.map((loc) => {
            const isBihar = loc.id === BIHAR_ID;
            return (
              <path
                key={loc.id}
                d={loc.path}
                className={
                  isBihar
                    ? "fill-orange stroke-orange"
                    : "fill-muted-foreground/20 stroke-background"
                }
                strokeWidth={1}
              />
            );
          })}
        </svg>

        {/* Bihar callout */}
        <div
          className="pointer-events-none absolute flex items-center gap-1"
          style={{
            left: `${(BIHAR_LABEL.x / 612) * 100}%`,
            top: `${(BIHAR_LABEL.y / 696) * 100}%`,
          }}
        >
          <span className="h-2 w-2 shrink-0 animate-ping rounded-full bg-orange" />
          <span className="absolute h-2 w-2 shrink-0 rounded-full bg-orange" />
        </div>
        <div
          className="pointer-events-none absolute -translate-y-full rounded-lg border border-orange/30 bg-background/90 px-2 py-1 text-[10px] font-bold leading-tight text-orange shadow-sm backdrop-blur sm:text-[11px]"
          style={{
            left: `${(BIHAR_LABEL.x / 612) * 100 + 4}%`,
            top: `${(BIHAR_LABEL.y / 696) * 100 - 2}%`,
          }}
        >
          BIHAR
          <div className="font-medium text-muted-foreground">Live now</div>
        </div>
      </div>

      {/* Footer strip */}
      <div className="flex items-center justify-center gap-1.5 border-t border-border bg-background/60 px-4 py-2.5 text-center text-[11px] font-semibold text-muted-foreground">
        Starting in Bihar, Building for All of India
      </div>
    </div>
  );
}
