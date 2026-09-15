import { createFileRoute, Link } from "@tanstack/react-router";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { ArrowRight, CreditCard } from "lucide-react";

const cats = [
  { name: "Men's Wear", img: "category-mens.jpg", desc: "Shirts, T-shirts, Jeans, Kurtas, Ethnic" },
  { name: "Women's Wear", img: "category-womens.jpg", desc: "Sarees, Kurtis, Lehengas, Western wear" },
  { name: "Kids Wear", img: "category-kids.jpg", desc: "Boys, Girls, Infants, School uniforms" },
  { name: "Footwear", img: "category-footwear.jpg", desc: "Men, Women, Kids — formal, casual, sports" },
];

export const Route = createFileRoute("/shop/fashion")({
  head: () => ({
    meta: [
      { title: "Fashion — VyparHub Shop" },
      { name: "description", content: "Men's, Women's, Kids and Footwear — factory-direct B2B fashion with Pay Later." },
    ],
  }),
  component: Page,
});

function Page() {
  return (
    <div className="min-h-screen bg-background">
      <SiteHeader />
      <main>
        <section className="relative overflow-hidden bg-foreground py-20 text-background">
          <div className="absolute inset-0 bg-[url('/images/product-saree.jpg')] bg-cover bg-center opacity-20" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <span className="inline-flex items-center gap-2 rounded-full bg-brand/20 px-3 py-1 text-xs font-bold text-brand-foreground">
              <CreditCard className="h-3.5 w-3.5" /> PAY LATER AVAILABLE
            </span>
            <h1 className="mt-4 font-display text-5xl font-black sm:text-6xl">
              Fashion <span className="text-gradient-brand">Shop</span>
            </h1>
            <p className="mt-3 max-w-xl text-background/80">
              Factory-direct fashion for India's Tier 2, 3, 4 retailers. 4 categories,
              hundreds of styles, all with Pay Later credit.
            </p>
          </div>
        </section>

        <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
          <div className="grid gap-6 sm:grid-cols-2">
            {cats.map((c) => (
              <Link
                key={c.name}
                to="/shop/fashion"
                className="group relative overflow-hidden rounded-3xl border border-border bg-card transition hover:-translate-y-1 hover:shadow-glow"
              >
                <div className="aspect-[4/3] overflow-hidden">
                  <img src={`/images/${c.img}`} alt={c.name} loading="lazy" className="h-full w-full object-cover transition duration-700 group-hover:scale-110" />
                </div>
                <div className="p-6">
                  <h3 className="font-display text-2xl font-black">{c.name}</h3>
                  <p className="mt-2 text-sm text-muted-foreground">{c.desc}</p>
                  <span className="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-brand">
                    Explore <ArrowRight className="h-4 w-4 transition group-hover:translate-x-1" />
                  </span>
                </div>
              </Link>
            ))}
          </div>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
