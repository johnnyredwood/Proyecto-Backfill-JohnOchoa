CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.qb_invoices (
  id TEXT PRIMARY KEY,
  payload JSONB NOT NULL,
  ingested_at_utc TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  extract_window_start_utc TIMESTAMP WITH TIME ZONE NOT NULL,
  extract_window_end_utc TIMESTAMP WITH TIME ZONE NOT NULL,
  page_number INTEGER,
  page_size INTEGER,
  request_payload JSONB,
  source_realm_id TEXT,
  source_env TEXT
);

CREATE TABLE IF NOT EXISTS raw.qb_customers (
  id TEXT PRIMARY KEY,
  payload JSONB NOT NULL,
  ingested_at_utc TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  extract_window_start_utc TIMESTAMP WITH TIME ZONE NOT NULL,
  extract_window_end_utc TIMESTAMP WITH TIME ZONE NOT NULL,
  page_number INTEGER,
  page_size INTEGER,
  request_payload JSONB,
  source_realm_id TEXT,
  source_env TEXT
);

CREATE TABLE IF NOT EXISTS raw.qb_items (
  id TEXT PRIMARY KEY,
  payload JSONB NOT NULL,
  ingested_at_utc TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  extract_window_start_utc TIMESTAMP WITH TIME ZONE NOT NULL,
  extract_window_end_utc TIMESTAMP WITH TIME ZONE NOT NULL,
  page_number INTEGER,
  page_size INTEGER,
  request_payload JSONB,
  source_realm_id TEXT,
  source_env TEXT
);

CREATE INDEX IF NOT EXISTS idx_qb_invoices_ingested_at ON raw.qb_invoices (ingested_at_utc);
CREATE INDEX IF NOT EXISTS idx_qb_customers_ingested_at ON raw.qb_customers (ingested_at_utc);
CREATE INDEX IF NOT EXISTS idx_qb_items_ingested_at ON raw.qb_items (ingested_at_utc);
