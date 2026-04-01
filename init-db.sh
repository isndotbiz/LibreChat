#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS tier45_evaluations_v2 (
  id BIGSERIAL PRIMARY KEY,
  model_name TEXT,
  category_name TEXT,
  technique_name TEXT,
  compliant BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS technique_model_scores (
  id BIGSERIAL PRIMARY KEY,
  model_id TEXT,
  model_family TEXT,
  technique_name TEXT NOT NULL,
  successes INTEGER DEFAULT 0,
  attempts INTEGER DEFAULT 0,
  win_rate DOUBLE PRECISION DEFAULT 0,
  ema_score DOUBLE PRECISION DEFAULT 0,
  status TEXT DEFAULT 'ACTIVE',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tier45_model_name ON tier45_evaluations_v2(model_name);
CREATE INDEX IF NOT EXISTS idx_tier45_technique_name ON tier45_evaluations_v2(technique_name);
CREATE INDEX IF NOT EXISTS idx_scores_model_family ON technique_model_scores(model_family);
CREATE INDEX IF NOT EXISTS idx_scores_model_id ON technique_model_scores(model_id);
SQL
