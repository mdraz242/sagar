ALTER TABLE banners
  ADD COLUMN IF NOT EXISTS subtitle TEXT,
  ADD COLUMN IF NOT EXISTS cta_text TEXT,
  ADD COLUMN IF NOT EXISTS cta_action TEXT,
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS config JSONB NOT NULL DEFAULT '{}'::jsonb;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'banners'
      AND column_name = 'display_order'
  ) THEN
    EXECUTE 'UPDATE banners SET sort_order = COALESCE(sort_order, display_order, 0)';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS banners_archived_idx ON banners(archived_at);
CREATE INDEX IF NOT EXISTS banners_active_window_idx ON banners(active, starts_at, ends_at);
