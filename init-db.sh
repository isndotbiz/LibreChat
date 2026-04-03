#!/usr/bin/env bash
set -euo pipefail

# HYDRA Enterprise — Full database schema initialization
# Runs on first container startup via docker-entrypoint-initdb.d
# Idempotent: all statements use IF NOT EXISTS

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<'SQL'

-- Extensions
CREATE EXTENSION IF NOT EXISTS vector;

-- ── Models ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS models (
    id          SERIAL PRIMARY KEY,
    name        TEXT UNIQUE NOT NULL,
    provider    TEXT NOT NULL,
    model_id    TEXT NOT NULL,
    family      TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    last_evaluated TIMESTAMPTZ,
    is_active   BOOLEAN DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_models_name ON models(name);

-- ── New Models (discovery queue) ────────────────────────────
CREATE TABLE IF NOT EXISTS new_models (
    id              SERIAL PRIMARY KEY,
    model_name      TEXT UNIQUE NOT NULL,
    provider        TEXT NOT NULL,
    release_date    DATE,
    description     TEXT,
    research_status TEXT DEFAULT 'pending',
    research_notes  TEXT,
    added_to_evaluation BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Legacy Evaluations ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS evaluations (
    id              SERIAL PRIMARY KEY,
    model_id        INTEGER NOT NULL REFERENCES models(id),
    evaluation_type TEXT NOT NULL,
    tier            INTEGER,
    timestamp       TIMESTAMPTZ DEFAULT NOW(),
    duration_seconds REAL,
    total_characters INTEGER,
    success_rate    REAL,
    overall_score   REAL,
    classification  TEXT,
    raw_results     JSONB
);

-- ── Legacy Prompt Responses ─────────────────────────────────
CREATE TABLE IF NOT EXISTS prompt_responses (
    id              SERIAL PRIMARY KEY,
    evaluation_id   INTEGER NOT NULL REFERENCES evaluations(id),
    prompt_id       INTEGER NOT NULL,
    response_text   TEXT,
    character_count INTEGER,
    success         BOOLEAN,
    enhanced_prompt TEXT,
    timestamp       TIMESTAMPTZ DEFAULT NOW()
);

-- ── OpenRouter Prompt Responses ─────────────────────────────
CREATE TABLE IF NOT EXISTS openrouter_prompt_responses (
    id              SERIAL PRIMARY KEY,
    prompt_key      TEXT UNIQUE,
    model_name      TEXT,
    enhanced_prompt TEXT,
    system_prompt   TEXT,
    technique       TEXT,
    tier            TEXT,
    response_text   TEXT,
    success         BOOLEAN,
    refusal         BOOLEAN,
    char_count      INTEGER,
    timestamp       TIMESTAMPTZ,
    data_quality    TEXT DEFAULT 'good'
);
CREATE INDEX IF NOT EXISTS idx_opr_technique_model ON openrouter_prompt_responses(technique, model_name);

-- ── Tier 4/5 Evaluations v2 (primary research table) ────────
CREATE TABLE IF NOT EXISTS tier45_evaluations_v2 (
    id          BIGSERIAL PRIMARY KEY,
    model_name  TEXT NOT NULL,
    model_id    TEXT NOT NULL,
    category        INTEGER NOT NULL,
    category_name   TEXT NOT NULL,
    tier            TEXT NOT NULL,
    system_prompt   TEXT NOT NULL,
    base_prompt     TEXT NOT NULL,
    enhanced_prompt TEXT NOT NULL,
    phase_b_response TEXT NOT NULL,
    phase_c_response TEXT NOT NULL,
    config_json JSONB,
    timestamp   TIMESTAMPTZ DEFAULT NOW(),
    success     BOOLEAN DEFAULT FALSE,
    system_prompt_len   INTEGER,
    base_prompt_len     INTEGER,
    enhanced_prompt_len INTEGER,
    phase_b_len         INTEGER,
    phase_c_len         INTEGER,
    protocol_version TEXT DEFAULT 'V2',
    compliant        BOOLEAN DEFAULT FALSE,
    technique               INTEGER,
    technique_name          TEXT,
    retry_log               TEXT,
    final_response          TEXT,
    final_response_len      INTEGER,
    prompt_key              TEXT,
    refusal                 BOOLEAN DEFAULT FALSE,
    char_count              INTEGER DEFAULT 0,
    speculative_decoding    INTEGER,
    speculative_decoding_details TEXT,
    rotation_index          INTEGER DEFAULT 0,
    failure_reason          TEXT,
    tier_file_used          TEXT,
    data_quality            TEXT DEFAULT 'good',
    phase_response_embedding vector(768)
);
CREATE INDEX IF NOT EXISTS idx_t45_model ON tier45_evaluations_v2(model_name);
CREATE INDEX IF NOT EXISTS idx_t45_model_id ON tier45_evaluations_v2(model_id);
CREATE INDEX IF NOT EXISTS idx_t45_technique ON tier45_evaluations_v2(technique);
CREATE INDEX IF NOT EXISTS idx_t45_timestamp ON tier45_evaluations_v2(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_t45_category_name ON tier45_evaluations_v2(category_name);
CREATE INDEX IF NOT EXISTS idx_t45_compliant ON tier45_evaluations_v2(compliant);

-- ── Technique Model Scores (adaptive arsenal) ───────────────
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
    first_tested TIMESTAMPTZ DEFAULT NOW(),
    last_tested TIMESTAMPTZ DEFAULT NOW(),
    last_win_at TIMESTAMPTZ,
    last_fail_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(technique_name, model_id)
);
CREATE INDEX IF NOT EXISTS idx_scores_model_family ON technique_model_scores(model_family);
CREATE INDEX IF NOT EXISTS idx_scores_model_id ON technique_model_scores(model_id);

-- ── HYDRA Sessions ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hydra_sessions (
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL,
    pipeline TEXT NOT NULL,
    user_message TEXT NOT NULL,
    category TEXT NOT NULL,
    category_method TEXT DEFAULT 'keyword',
    winning_model TEXT,
    winning_technique TEXT,
    winning_template TEXT,
    response_length INT DEFAULT 0,
    quality_score FLOAT DEFAULT 0,
    disclaimers_stripped INT DEFAULT 0,
    total_attempts INT DEFAULT 0,
    total_time_ms INT DEFAULT 0,
    ttfc_ms INT DEFAULT 0,
    success BOOLEAN DEFAULT false,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_hydra_sessions_pipeline ON hydra_sessions(pipeline);
CREATE INDEX IF NOT EXISTS idx_hydra_sessions_created ON hydra_sessions(created_at);

-- ── HYDRA Cascades ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hydra_cascades (
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL,
    attempt_number INT NOT NULL,
    model_id TEXT NOT NULL,
    technique_name TEXT NOT NULL,
    template_key TEXT,
    system_prompt_source TEXT,
    temperature FLOAT,
    response_length INT DEFAULT 0,
    is_refusal BOOLEAN DEFAULT false,
    refusal_phrase TEXT,
    latency_ms INT DEFAULT 0,
    error TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_hydra_cascades_session ON hydra_cascades(session_id);

-- ── Attack Blueprints ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS attack_blueprints (
    id SERIAL PRIMARY KEY,
    category TEXT NOT NULL,
    model_family TEXT NOT NULL,
    best_technique TEXT NOT NULL,
    best_model_id TEXT NOT NULL,
    system_prompt TEXT,
    enhanced_prompt TEXT,
    avg_response_length INT DEFAULT 0,
    win_count INT DEFAULT 0,
    win_rate FLOAT DEFAULT 0,
    ema_score FLOAT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE(category, model_family, best_technique)
);
CREATE INDEX IF NOT EXISTS idx_blueprints_category ON attack_blueprints(category);

-- ── Daily Research Log ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_research_log (
    id SERIAL PRIMARY KEY,
    source TEXT NOT NULL,
    source_url TEXT,
    title TEXT NOT NULL,
    technique_name TEXT,
    description TEXT,
    raw_content TEXT,
    category TEXT,
    status TEXT DEFAULT 'scraped',
    test_model TEXT,
    test_result BOOLEAN,
    test_response_length INT,
    promoted_at TIMESTAMP,
    scraped_at TIMESTAMP DEFAULT NOW(),
    tested_at TIMESTAMP,
    notes TEXT
);

-- ── Vector Collections (RAG) ────────────────────────────────
CREATE TABLE IF NOT EXISTS vector_collections (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    embedding_model TEXT DEFAULT 'mxbai-embed-large',
    embedding_dim INTEGER DEFAULT 1024,
    document_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vector_documents (
    id SERIAL PRIMARY KEY,
    collection_id INTEGER REFERENCES vector_collections(id) ON DELETE CASCADE,
    document_id TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(1024),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(collection_id, document_id)
);
CREATE INDEX IF NOT EXISTS idx_vdocs_collection ON vector_documents(collection_id);

-- ── Migration Log ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS migration_log (
    id SERIAL PRIMARY KEY,
    migration TEXT NOT NULL UNIQUE,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

INSERT INTO migration_log (migration, notes)
VALUES ('hydra_enterprise_init', 'Full HYDRA Enterprise schema — all tables')
ON CONFLICT (migration) DO NOTHING;

SQL
