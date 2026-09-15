import { Link } from "@tanstack/react-router";
import { ArrowRight, Clock, CreditCard, Store, Truck } from "lucide-react";

export function TwoCategories() {
  return (
    <section id="categories" className="relative py-12 sm:py-16">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <span className="text-[11px] font-bold uppercase tracking-[0.2em] text-orange">
            Do business verticals
          </span>
          <h2 className="mt-2 font-display text-2xl font-black tracking-tight sm:text-3xl">
            Sirf <span className="text-gradient-brand">do category</span> — sab kuch ek jagah
          </h2>
          <p className="mt-2 text-sm text-muted-foreground">
            Faltu options nahi. Sirf jo dukandaar ko chahiye — FMCG aur Fashion.
          </p>
        </div>

        <div className="mt-8 grid gap-5 md:grid-cols-2">
          {/* FMCG */}
          <Link
            to="/shop/fmcg"
            className="group relative overflow-hidden rounded-2xl border border-border bg-card p-5 shadow-sm transition hover:-translate-y-1 hover:border-brand/40 hover:shadow-glow"
          >
            <div className="flex items-center gap-2">
              <div className="grid h-10 w-10 place-items-center rounded-lg bg-brand-gradient text-brand-foreground">
                <Store className="h-5 w-5" />
              </div>
              <span className="inline-flex items-center gap-1 rounded-full bg-brand/10 px-2.5 py-1 text-[10px] font-bold text-brand">
                <Clock className="h-3 w-3" /> 2 HOUR DELIVERY
              </span>
            </div>
            <h3 className="mt-3 font-display text-2xl font-black">FMCG</h3>
            <p className="mt-1.5 text-sm text-muted-foreground">
              Kirana ke liye — biscuits, snacks, oil, dal, soap, masale, cold drinks.
              Direct brand pricing, 2 ghante delivery.
            </p>
            <div className="mt-4 grid grid-cols-3 gap-2">
              {["fmcg-products.jpg", "retailer-kirana-1.jpg", "retailer-kirana-2.jpg"].map((s) => (
                <img
                  key={s}
                  src={`/images/${s}`}
                  alt="Real kirana FMCG"
                  loading="lazy"
                  className="aspect-square w-full rounded-md object-cover"
                />
              ))}
            </div>
            <div className="mt-4 flex items-center justify-between">
              <span className="inline-flex items-center gap-1 text-xs font-semibold text-brand">
                Browse FMCG <ArrowRight className="h-3.5 w-3.5 transition group-hover:translate-x-1" />
              </span>
              <span className="text-[10px] text-muted-foreground">200+ brands</span>
            </div>
          </Link>

          {/* Fashion */}
          <Link
            to="/shop/fashion"
            className="group relative overflow-hidden rounded-2xl border border-border bg-card p-5 shadow-sm transition hover:-translate-y-1 hover:border-orange/40 hover:shadow-glow-orange"
          >
            <div className="flex items-center gap-2">
              <div className="grid h-10 w-10 place-items-center rounded-lg bg-orange-gradient text-orange-foreground">
                <Truck className="h-5 w-5" />
              </div>
              <span className="inline-flex items-center gap-1 rounded-full bg-orange/15 px-2.5 py-1 text-[10px] font-bold text-orange">
                <CreditCard className="h-3 w-3" /> PAY LATER
              </span>
            </div>
            <h3 className="mt-3 font-display text-2xl font-black">Fashion</h3>
            <p className="mt-1.5 text-sm text-muted-foreground">
              Men's, Women's, Kids, Footwear — factory pricing, Pay Later, all-India dispatch.
            </p>
            <div className="mt-4 grid grid-cols-4 gap-2">
              {["category-mens.jpg", "category-womens.jpg", "category-kids.jpg", "category-footwear.jpg"].map((s) => (
                <img
                  key={s}
                  src={`/images/${s}`}
                  alt="Fashion category"
                  loading="lazy"
                  className="aspect-square w-full rounded-md object-cover"
                />
              ))}
            </div>
            <div className="mt-4 flex items-center justify-between">
              <span className="inline-flex items-center gap-1 text-xs font-semibold text-orange">
                Browse Fashion <ArrowRight className="h-3.5 w-3.5 transition group-hover:translate-x-1" />
              </span>
              <span className="text-[10px] text-muted-foreground">4 sub-categories</span>
            </div>
          </Link>
        </div>
      </div>
    </section>
  );
}
