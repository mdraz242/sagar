import { Link, useNavigate } from "@tanstack/react-router";
import { ArrowLeft, CheckCircle2, Shirt } from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import { supabase } from "@/integrations/supabase/client";
import { useLang } from "@/i18n/LanguageContext";

const schema = z.object({
  full_name: z.string().trim().min(2, "Enter your name").max(100),
  phone: z.string().trim().regex(/^[6-9]\d{9}$/, "Enter a valid 10-digit Indian mobile"),
  address: z.string().trim().min(5, "Enter full address").max(500),
  shop_name: z.string().trim().max(150).optional().or(z.literal("")),
});

export function RetailerApplyForm({
  category,
  bgImage,
  accent,
  Icon,
  title,
  subtitle,
}: {
  category: "retailer-fashion" | "retailer-fmcg";
  bgImage: string;
  accent: "brand" | "orange";
  Icon: typeof Shirt;
  title: string;
  subtitle: string;
}) {
  const { t } = useLang();
  const navigate = useNavigate();
  const [done, setDone] = useState(false);
  const [full_name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [shop_name, setShop] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const gradCls = accent === "brand" ? "bg-brand-gradient text-brand-foreground shadow-glow" : "bg-orange-gradient text-orange-foreground shadow-glow-orange";

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    const parsed = schema.safeParse({ full_name, phone, address, shop_name });
    if (!parsed.success) { setErr(parsed.error.issues[0].message); return; }
    setSaving(true);
    const { error } = await supabase.from("retailer_applications").insert({
      category,
      full_name: parsed.data.full_name,
      phone: parsed.data.phone,
      address: parsed.data.address,
      shop_name: parsed.data.shop_name || "—",
    });
    setSaving(false);
    if (error) { setErr(error.message); return; }
    setDone(true);
  }

  return (
    <div className="relative min-h-screen px-4 py-10">
      <div className="absolute inset-0 -z-10 bg-cover bg-center" style={{ backgroundImage: `url('${bgImage}')` }} aria-hidden />
      <div className="absolute inset-0 -z-10 bg-background/80 backdrop-blur-sm" aria-hidden />

      <div className="mx-auto max-w-lg">
        <Link to="/" className="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-foreground hover:text-brand">
          <ArrowLeft className="h-4 w-4" /> {t("back")}
        </Link>

        <div className="rounded-3xl border border-border bg-card/95 p-7 shadow-2xl backdrop-blur">
          {!done ? (
            <>
              <div className={`grid h-12 w-12 place-items-center rounded-xl ${gradCls}`}>
                <Icon className="h-6 w-6" />
              </div>
              <h1 className="mt-4 font-display text-2xl font-black">{title}</h1>
              <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>

              <form className="mt-6 space-y-3" onSubmit={submit}>
                <input
                  value={full_name} onChange={(e) => setName(e.target.value)}
                  placeholder={t("fullName")} maxLength={100}
                  className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
                />
                <input
                  value={phone} onChange={(e) => setPhone(e.target.value.replace(/\D/g, "").slice(0, 10))}
                  placeholder={t("mobileNumber")} inputMode="numeric"
                  className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
                />
                <textarea
                  value={address} onChange={(e) => setAddress(e.target.value)}
                  placeholder={t("address")} rows={3} maxLength={500}
                  className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
                />
                <input
                  value={shop_name} onChange={(e) => setShop(e.target.value)}
                  placeholder={`${t("shopOrCompany")} (${t("optional")})`} maxLength={150}
                  className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
                />
                {err && <p className="text-xs font-semibold text-red-600">{err}</p>}
                <button disabled={saving} className={`w-full rounded-xl ${gradCls} py-3 text-sm font-bold disabled:opacity-60`}>
                  {saving ? t("submitting") : t("submit")}
                </button>
              </form>
            </>
          ) : (
            <div className="py-4 text-center">
              <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-green-100 text-green-600">
                <CheckCircle2 className="h-9 w-9" />
              </div>
              <h2 className="mt-4 font-display text-2xl font-black">{t("retailerDoneTitle")}</h2>
              <p className="mt-2 text-sm text-muted-foreground">{t("retailerDoneMsg")}</p>

              <p className="mt-6 text-sm font-semibold text-foreground">Hamare team jald aapko call karenge.</p>

              <button onClick={() => navigate({ to: "/" })} className="mt-6 text-xs font-semibold text-muted-foreground hover:text-foreground">
                ← {t("goHome")}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
