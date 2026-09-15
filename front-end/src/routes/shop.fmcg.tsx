import { createFileRoute, Link } from "@tanstack/react-router";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { Clock } from "lucide-react";

const cats = [
  "Namkeens & Chips", "Oral Care", "Tea, Coffee & More", "Personal Care",
  "Hair Care", "Biscuits & Cookies", "Dairy, Bread & Eggs", "Dry Fruits & Nuts",
  "Chocolates & Toffees", "Cold Drink & Juices", "Cleaning Essentials", "Paan Corner",
  "Instant Food", "Pooja Store", "Soaps & Creams", "Freezers & Chillers",
  "Spices", "Health Care", "Ghee & Oil", "Kirane Ka Saman",
  "Disposables", "Appliances", "Top Deal Combos",
];
const imgs = [
  "trust-margin.jpg","step-stock.jpg","trust-call-support.jpg","trust-verified.jpg",
  "step-payment.jpg","trust-pay-later.jpg","factory.jpg","factory-2.jpg",
];

export const Route = createFileRoute("/shop/fmcg")({
  head: () => ({
    meta: [
      { title: "FMCG — VyparHub Shop (2 Hour Delivery)" },
      { name: "description", content: "Kirana store FMCG — biscuits, snacks, oil, spices, personal care. 2-hour delivery with Pay Later credit." },
    ],
  }),
  component: Page,
});

function Page() {
  return (
    <div className="min-h-screen bg-background">
      <SiteHeader />
      <main>
        <section className="relative overflow-hidden bg-brand-gradient py-20 text-brand-foreground">
          <div className="absolute inset-0 bg-[url('/images/trust-margin.jpg')] bg-cover bg-center opacity-15" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <span className="inline-flex items-center gap-2 rounded-full bg-background/20 px-3 py-1 text-xs font-bold backdrop-blur">
              <Clock className="h-3.5 w-3.5" /> 2 HOUR DELIVERY
            </span>
            <h1 className="mt-4 font-display text-5xl font-black sm:text-6xl">FMCG Shop</h1>
            <p className="mt-3 max-w-xl text-brand-foreground/90">
              Bharat ke kirana stores ke liye — biscuits, snacks, oil, dal, soap, masale.
              Real prices. Pay Later. 2 ghante mein delivery.
            </p>
          </div>
        </section>

        <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {cats.map((name, i) => (
              <Link
                key={name}
                to="/shop/fmcg"
                className="group flex flex-col items-center rounded-2xl border border-border bg-card p-4 text-center transition hover:-translate-y-1 hover:border-brand/40 hover:shadow-glow"
              >
                <div className="grid aspect-square w-full place-items-center overflow-hidden rounded-xl bg-muted">
                  <img src={`/images/${imgs[i % imgs.length]}`} alt={name} loading="lazy" className="h-full w-full object-cover transition duration-500 group-hover:scale-110" />
                </div>
                <div className="mt-3 text-sm font-semibold">{name}</div>
                <span className="mt-1 text-[10px] font-bold uppercase text-brand">2 hr delivery</span>
              </Link>
            ))}
          </div>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
