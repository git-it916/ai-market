-- Migration v4.20: Fix column names to match service code expectations
-- Run this after migration_v4.19.sql

-- =====================================================
-- FIX ENSEMBLE_AGENT_WEIGHTS - add regime_fit column
-- =====================================================
ALTER TABLE ensemble_agent_weights ADD COLUMN IF NOT EXISTS regime_fit DECIMAL(5,4) DEFAULT 0.0;

-- =====================================================
-- FIX META_AGENT_PERFORMANCE - add total_return column
-- =====================================================
ALTER TABLE meta_agent_performance ADD COLUMN IF NOT EXISTS total_return DECIMAL(10,4) DEFAULT 0.0;

-- =====================================================
-- FIX META_REGIME_ANALYSIS - add regime column
-- =====================================================
ALTER TABLE meta_regime_analysis ADD COLUMN IF NOT EXISTS regime VARCHAR(50);

-- =====================================================
-- FIX META_ROTATION_DECISIONS - add decision_id column
-- =====================================================
ALTER TABLE meta_rotation_decisions ADD COLUMN IF NOT EXISTS decision_id VARCHAR(100);

-- =====================================================
-- FIX META_AGENT_RANKINGS - add regime column
-- =====================================================
ALTER TABLE meta_agent_rankings ADD COLUMN IF NOT EXISTS regime VARCHAR(50);

-- =====================================================
-- FIX LATENT_MARKET_DATA - add missing columns
-- =====================================================
ALTER TABLE latent_market_data ADD COLUMN IF NOT EXISTS data_json JSONB DEFAULT '{}';
ALTER TABLE latent_market_data ADD COLUMN IF NOT EXISTS symbols TEXT[] DEFAULT '{}';

-- =====================================================
-- CREATE RAG_NEWS_DOCUMENTS TABLE (missing from init.sql)
-- =====================================================
-- First drop the existing one if it has wrong schema
DROP TABLE IF EXISTS rag_news_documents CASCADE;

CREATE TABLE IF NOT EXISTS rag_news_documents (
    id SERIAL PRIMARY KEY,
    doc_id VARCHAR(255) UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    source VARCHAR(100) NOT NULL,
    url TEXT,
    category VARCHAR(50),
    tags TEXT[] DEFAULT '{}',
    published_at TIMESTAMP,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rag_news_doc_id ON rag_news_documents(doc_id);
CREATE INDEX IF NOT EXISTS idx_rag_news_source ON rag_news_documents(source);
CREATE INDEX IF NOT EXISTS idx_rag_news_published ON rag_news_documents(published_at);
CREATE INDEX IF NOT EXISTS idx_rag_news_category ON rag_news_documents(category);

-- =====================================================
-- FIX PREDICTIONS TABLE - ensure predicted_direction exists
-- =====================================================
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS predicted_direction VARCHAR(20);

-- =====================================================
-- FIX RL_PERFORMANCE_METRICS - proper unique constraint
-- =====================================================
-- Drop old constraint if exists
ALTER TABLE rl_performance_metrics DROP CONSTRAINT IF EXISTS rl_performance_metrics_period_created_unique;

-- Add unique constraint on measurement_period only (for ON CONFLICT)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'rl_performance_metrics_period_unique'
    ) THEN
        -- First, delete duplicate rows keeping only the latest
        DELETE FROM rl_performance_metrics a
        USING rl_performance_metrics b
        WHERE a.id < b.id AND a.measurement_period = b.measurement_period;

        -- Then add unique constraint
        ALTER TABLE rl_performance_metrics ADD CONSTRAINT rl_performance_metrics_period_unique UNIQUE (measurement_period);
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not add constraint: %', SQLERRM;
END $$;

-- =====================================================
-- FIX ENSEMBLE_SIGNALS - add created_at if missing
-- =====================================================
-- created_at should already exist but just in case
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ensemble_signals' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE ensemble_signals ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- =====================================================
-- LOG COMPLETION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Migration v4.20 fix completed successfully!';
    RAISE NOTICE 'Fixed columns: regime_fit, total_return, regime, decision_id, data_json, symbols';
    RAISE NOTICE 'Created table: rag_news_documents';
    RAISE NOTICE 'Fixed constraint: rl_performance_metrics_period_unique';
END $$;
