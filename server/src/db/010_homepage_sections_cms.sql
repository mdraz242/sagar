ALTER TABLE home_sections
  ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'product_carousel',
  ADD COLUMN IF NOT EXISTS config JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE home_sections
SET type = 'product_carousel'
WHERE type IS NULL OR type = '';

CREATE INDEX IF NOT EXISTS home_sections_type_idx ON home_sections(type);
