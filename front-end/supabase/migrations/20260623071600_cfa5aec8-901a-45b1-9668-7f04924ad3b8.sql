CREATE TABLE IF NOT EXISTS public.retailer_applications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL CHECK (category IN ('retailer-fmcg','retailer-fashion')),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  shop_name TEXT NOT NULL DEFAULT '—',
  address TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT INSERT ON public.retailer_applications TO anon, authenticated;
GRANT ALL ON public.retailer_applications TO service_role;
ALTER TABLE public.retailer_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can submit retailer application"
  ON public.retailer_applications FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);