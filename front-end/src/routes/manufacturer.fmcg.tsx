import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { ArrowLeft, CheckCircle2, Package } from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import { supabase } from "@/integrations/supabase/client";
import { useLang } from "@/i18n/LanguageContext";

export const Route = createFileRoute("/manufacturer/fmcg")({
  head: () => ({
    meta: [
      { title: "FMCG / Kirana Manufacturer Application — VyparHub" },
      { name: "description", content: "Apply to list your FMCG / Kirana brand on VyparHub's B2B network." },
    ],
  }),
  component: FmcgApply,
});

const schema = z.object({
  full_name: z.string().trim().min(2, "Enter your name").max(100),
  phone: z.string().trim().regex(/^[6-9]\d{9}$/, "Enter a valid 10-digit Indian mobile"),
  shop_name: z.string().trim().min(2, "Enter shop / company").max(150),
  address: z.string().trim().min(5, "Enter full address").max(500),
});

type Step = "details" | "otp" | "business" | "done";

function FmcgApply() {
  const { t } = useLang();
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>("details");
  const [full_name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [shop_name, setShop] = useState("");
  const [address, setAddress] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function submit() {
    setErr(null);
    const parsed = schema.safeParse({ full_name, phone, shop_name, address });
    if (!parsed.success) { setErr(parsed.error.issues[0].message); return; }
    setSaving(true);
    const { error } = await supabase.from("manufacturer_applications").insert({
      category: "fmcg",
      ...parsed.data,
    });
    setSaving(false);
    if (error) { setErr(error.message); return; }
    setStep("done");
  }

  return (
    <div className="relative min-h-screen px-4 py-10">
      {/* Background: real FMCG kirana shop photo */}
      <div
        className="absolute inset-0 -z-10 bg-cover bg-center"
        style={{ backgroundImage: "url('/images/fmcg-shop-bg.jpg')" }}
        aria-hidden
      />
      <div className="absolute inset-0 -z-10 bg-background/80 backdrop-blur-sm" aria-hidden />

      <div className="mx-auto max-w-lg">
        <Link to="/" className="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-foreground hover:text-brand">
          <ArrowLeft className="h-4 w-4" /> {t("back")}
        </Link>

        <div className="rounded-3xl border border-border bg-card/95 p-7 shadow-2xl backdrop-blur">
          {step !== "done" && (
            <>
              <div className="grid h-12 w-12 place-items-center rounded-xl bg-brand-gradient text-brand-foreground">
                <Package className="h-6 w-6" />
              </div>
              <h1 className="mt-4 font-display text-2xl font-black">{t("fmcgFormTitle")}</h1>
              <p className="mt-1 text-sm text-muted-foreground">{t("fmcgFormSub")}</p>
            </>
          )}

          {step === "details" && (
            <form
              className="mt-6 space-y-3"
              onSubmit={(e) => {
                e.preventDefault();
                setErr(null);
                const parsed = schema.safeParse({ full_name, phone, shop_name, address });
                if (!parsed.success) { setErr(parsed.error.issues[0].message); return; }
                setStep("otp");
              }}
            >
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
              <input
                value={shop_name} onChange={(e) => setShop(e.target.value)}
                placeholder={t("shopOrCompany")} maxLength={150}
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
              />
              <textarea
                value={address} onChange={(e) => setAddress(e.target.value)}
                placeholder={t("address")} rows={3} maxLength={500}
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-brand"
              />
              {err && <p className="text-xs font-semibold text-red-600">{err}</p>}
              <button className="w-full rounded-xl bg-brand-gradient py-3 text-sm font-bold text-brand-foreground shadow-glow">
                {t("sendOtpBtn")}
              </button>
            </form>
          )}

          {step === "otp" && (
            <form
              className="mt-6 space-y-3"
              onSubmit={(e) => {
                e.preventDefault();
                setErr(null);
                if (!/^\d{6}$/.test(otp)) { setErr(t("invalidOtp")); return; }
                submit();
              }}
            >
              <p className="rounded-xl bg-green-50 px-3 py-2 text-xs font-semibold text-green-700">
                {t("otpSent")} • +91 {phone}
              </p>
              <input
                value={otp} onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
                placeholder={t("enterOtp")} inputMode="numeric"
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-center text-lg font-bold tracking-[0.5em] outline-none focus:border-brand"
              />
              {err && <p className="text-xs font-semibold text-red-600">{err}</p>}
              <button disabled={saving} className="w-full rounded-xl bg-brand-gradient py-3 text-sm font-bold text-brand-foreground shadow-glow disabled:opacity-60">
                {saving ? t("submitting") : t("verifyContinue")}
              </button>
              <button type="button" onClick={() => setStep("details")} className="w-full text-xs text-muted-foreground hover:text-foreground">
                ← {t("back")}
              </button>
            </form>
          )}



          {step === "done" && (
            <div className="py-6 text-center">
              <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-green-100 text-green-600">
                <CheckCircle2 className="h-9 w-9" />
              </div>
              <h2 className="mt-4 font-display text-2xl font-black">{t("thanksTitle")}</h2>
              <p className="mt-2 text-sm text-muted-foreground">{t("thanksMsg")}</p>
              <button
                onClick={() => navigate({ to: "/" })}
                className="mt-6 rounded-xl bg-brand-gradient px-5 py-3 text-sm font-bold text-brand-foreground shadow-glow"
              >
                {t("goHome")}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
