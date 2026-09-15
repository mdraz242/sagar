CREATE TABLE IF NOT EXISTS public.manufacturer_applications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  shop_name TEXT NOT NULL DEFAULT '—',
  address TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT INSERT ON public.manufacturer_applications TO anon, authenticated;
GRANT ALL ON public.manufacturer_applications TO service_role;
ALTER TABLE public.manufacturer_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can submit manufacturer application"
  ON public.manufacturer_applications FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);