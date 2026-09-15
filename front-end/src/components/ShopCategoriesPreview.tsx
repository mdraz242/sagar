const fmcg = [
  { name: "Namkeens & Chips", img: "cat-namkeens.jpg" },
  { name: "Biscuits & Cookies", img: "cat-biscuits.jpg" },
  { name: "Tea, Coffee & More", img: "cat-tea-coffee.jpg" },
  { name: "Personal Care", img: "cat-personal-care.jpg" },
  { name: "Dairy, Bread & Eggs", img: "cat-dairy.jpg" },
  { name: "Cold Drink & Juices", img: "cat-cold-drinks.jpg" },
  { name: "Spices & Masale", img: "cat-spices.jpg" },
  { name: "Ghee & Oil", img: "cat-ghee-oil.jpg" },
  { name: "Oral Care", img: "cat-oral-care.jpg" },
  { name: "Hair Care", img: "cat-hair-care.jpg" },
  { name: "Dry Fruits & Nuts", img: "cat-dry-fruits.jpg" },
  { name: "Chocolates & Toffees", img: "cat-chocolates.jpg" },
  { name: "Cleaning Essentials", img: "cat-cleaning.jpg" },
  { name: "Paan Corner", img: "cat-paan.jpg" },
  { name: "Instant Food", img: "cat-instant-food.jpg" },
  { name: "Pooja Store", img: "cat-pooja.jpg" },
  { name: "Soaps & Creams", img: "cat-soaps-creams.jpg" },
  { name: "Freezers & Chillers", img: "cat-freezers.jpg" },
  { name: "Health Care", img: "cat-health-care.jpg" },
  { name: "Kirane Ka Saman", img: "cat-kirana.jpg" },
  { name: "Disposables", img: "cat-disposables.jpg" },
  { name: "Appliances", img: "cat-appliances.jpg" },
  { name: "Top Deal Combos", img: "cat-combos.jpg" },
];

export function ShopCategoriesPreview() {
  return (
    <section className="py-12 sm:py-16">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <span className="text-[11px] font-bold uppercase tracking-[0.2em] text-orange">Shop categories</span>
          <h2 className="mt-2 font-display text-2xl font-black tracking-tight sm:text-3xl">
            Browse by <span className="text-gradient-brand">category</span>
          </h2>
        </div>

        {/* FMCG — strict 2 rows, horizontally scrollable */}
        <div className="mt-8">
          <h3 className="font-display text-lg font-bold">
            FMCG
            <span className="ml-2 rounded-full bg-brand/10 px-2 py-0.5 text-[10px] font-bold text-brand">2 Hour Delivery</span>
          </h3>
          <div className="mt-3 -mx-4 overflow-x-auto px-4 pb-3 sm:mx-0 sm:px-0">
            <div className="grid grid-flow-col grid-rows-2 gap-2 sm:gap-3" style={{ gridAutoColumns: "140px" }}>
              {fmcg.map((c) => (
                <div
                  key={c.name}
                  className="flex cursor-default flex-col items-center rounded-xl border border-border bg-card p-2 text-center"
                >
                  <div className="grid aspect-square w-full place-items-center overflow-hidden rounded-lg bg-white">
                    <img
                      src={`/images/${c.img}`}
                      alt={c.name}
                      loading="lazy"
                      width={640}
                      height={640}
                      className="h-full w-full object-cover"
                    />
                  </div>
                  <div className="mt-2 text-[11px] font-semibold leading-tight">{c.name}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
