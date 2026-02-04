-- Migration v4.21: Complete fix for all missing columns
-- Run this to fix ALL database schema issues

-- =====================================================
-- DROP AND RECREATE TABLES WITH CORRECT SCHEMA
-- =====================================================

-- 1. META_AGENT_PERFORMANCE
DROP TABLE IF EXISTS meta_agent_performance CASCADE;
CREATE TABLE meta_agent_performance (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    accuracy DECIMAL(5,4) DEFAULT 0.0,
    sharpe_ratio DECIMAL(8,4) DEFAULT 0.0,
    total_return DECIMAL(10,4) DEFAULT 0.0,
    max_drawdown DECIMAL(8,4) DEFAULT 0.0,
    win_rate DECIMAL(5,4) DEFAULT 0.0,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    response_time DECIMAL(10,4) DEFAULT 0.0,
    regime VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_meta_agent_perf_agent ON meta_agent_performance(agent_name);
CREATE INDEX idx_meta_agent_perf_created ON meta_agent_performance(created_at);

-- 2. META_AGENT_RANKINGS
DROP TABLE IF EXISTS meta_agent_rankings CASCADE;
CREATE TABLE meta_agent_rankings (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    regime VARCHAR(50),
    rank INTEGER,
    composite_score DECIMAL(5,4) DEFAULT 0.0,
    accuracy DECIMAL(5,4) DEFAULT 0.0,
    sharpe_ratio DECIMAL(8,4) DEFAULT 0.0,
    total_return DECIMAL(10,4) DEFAULT 0.0,
    max_drawdown DECIMAL(8,4) DEFAULT 0.0,
    win_rate DECIMAL(5,4) DEFAULT 0.0,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    response_time DECIMAL(10,4) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_meta_rankings_agent ON meta_agent_rankings(agent_name);
CREATE INDEX idx_meta_rankings_regime ON meta_agent_rankings(regime);
CREATE INDEX idx_meta_rankings_created ON meta_agent_rankings(created_at);

-- 3. META_REGIME_ANALYSIS
DROP TABLE IF EXISTS meta_regime_analysis CASCADE;
CREATE TABLE meta_regime_analysis (
    id SERIAL PRIMARY KEY,
    regime VARCHAR(50) NOT NULL,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    volatility DECIMAL(8,4) DEFAULT 0.0,
    trend_strength DECIMAL(5,4) DEFAULT 0.0,
    volume_ratio DECIMAL(8,4) DEFAULT 0.0,
    trend_direction VARCHAR(20),
    market_indicators JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_meta_regime_regime ON meta_regime_analysis(regime);
CREATE INDEX idx_meta_regime_created ON meta_regime_analysis(created_at);

-- 4. META_ROTATION_DECISIONS
DROP TABLE IF EXISTS meta_rotation_decisions CASCADE;
CREATE TABLE meta_rotation_decisions (
    id SERIAL PRIMARY KEY,
    decision_id VARCHAR(100),
    from_agent VARCHAR(100),
    to_agent VARCHAR(100),
    reason TEXT,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    expected_improvement DECIMAL(8,4) DEFAULT 0.0,
    regime VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_meta_rotation_decision ON meta_rotation_decisions(decision_id);
CREATE INDEX idx_meta_rotation_created ON meta_rotation_decisions(created_at);

-- 5. LATENT_MARKET_DATA
DROP TABLE IF EXISTS latent_market_data CASCADE;
CREATE TABLE latent_market_data (
    id SERIAL PRIMARY KEY,
    symbols JSONB DEFAULT '[]',
    data_json JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_latent_market_created ON latent_market_data(created_at);

-- 6. LATENT_PATTERNS
DROP TABLE IF EXISTS latent_patterns CASCADE;
CREATE TABLE latent_patterns (
    id SERIAL PRIMARY KEY,
    pattern_id VARCHAR(100) UNIQUE,
    pattern_type VARCHAR(50),
    latent_dimensions JSONB DEFAULT '[]',
    explained_variance DECIMAL(8,4) DEFAULT 0.0,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    compression_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_latent_patterns_type ON latent_patterns(pattern_type);
CREATE INDEX idx_latent_patterns_created ON latent_patterns(created_at);

-- 7. LATENT_COMPRESSION_METRICS
DROP TABLE IF EXISTS latent_compression_metrics CASCADE;
CREATE TABLE latent_compression_metrics (
    id SERIAL PRIMARY KEY,
    method VARCHAR(50),
    compression_ratio DECIMAL(8,4) DEFAULT 0.0,
    reconstruction_error DECIMAL(8,4) DEFAULT 0.0,
    explained_variance DECIMAL(8,4) DEFAULT 0.0,
    processing_time DECIMAL(10,4) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_latent_compress_method ON latent_compression_metrics(method);

-- 8. LATENT_PATTERN_INSIGHTS
DROP TABLE IF EXISTS latent_pattern_insights CASCADE;
CREATE TABLE latent_pattern_insights (
    id SERIAL PRIMARY KEY,
    insight_id VARCHAR(100),
    pattern_type VARCHAR(50),
    description TEXT,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    market_implications JSONB DEFAULT '{}',
    recommendations JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_latent_insights_type ON latent_pattern_insights(pattern_type);

-- 9. ENSEMBLE_AGENT_SIGNALS
DROP TABLE IF EXISTS ensemble_agent_signals CASCADE;
CREATE TABLE ensemble_agent_signals (
    id SERIAL PRIMARY KEY,
    signal_id VARCHAR(100),
    agent_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(20),
    signal_type VARCHAR(20),
    confidence DECIMAL(5,4) DEFAULT 0.0,
    regime VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ensemble_agent_sig_agent ON ensemble_agent_signals(agent_name);
CREATE INDEX idx_ensemble_agent_sig_symbol ON ensemble_agent_signals(symbol);
CREATE INDEX idx_ensemble_agent_sig_created ON ensemble_agent_signals(created_at);

-- 10. ENSEMBLE_AGENT_WEIGHTS (fix)
DROP TABLE IF EXISTS ensemble_agent_weights CASCADE;
CREATE TABLE ensemble_agent_weights (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    weight DECIMAL(5,4) DEFAULT 0.0,
    regime_fit DECIMAL(5,4) DEFAULT 0.0,
    performance_score DECIMAL(5,4) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ensemble_weights_agent ON ensemble_agent_weights(agent_name);
CREATE INDEX idx_ensemble_weights_created ON ensemble_agent_weights(created_at);

-- 11. ENSEMBLE_SIGNALS (fix)
DROP TABLE IF EXISTS ensemble_signals CASCADE;
CREATE TABLE ensemble_signals (
    id SERIAL PRIMARY KEY,
    signal_id VARCHAR(100),
    symbol VARCHAR(20),
    signal_type VARCHAR(20),
    blended_confidence DECIMAL(5,4) DEFAULT 0.0,
    confidence DECIMAL(5,4) DEFAULT 0.0,
    regime VARCHAR(50),
    blend_mode VARCHAR(50),
    quality_score DECIMAL(5,4) DEFAULT 0.0,
    contributors JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ensemble_sig_symbol ON ensemble_signals(symbol);
CREATE INDEX idx_ensemble_sig_type ON ensemble_signals(signal_type);
CREATE INDEX idx_ensemble_sig_created ON ensemble_signals(created_at);

-- 12. ENSEMBLE_QUALITY_METRICS
DROP TABLE IF EXISTS ensemble_quality_metrics CASCADE;
CREATE TABLE ensemble_quality_metrics (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100),
    value DECIMAL(10,4) DEFAULT 0.0,
    threshold DECIMAL(10,4) DEFAULT 0.0,
    status VARCHAR(20),
    trend VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ensemble_quality_name ON ensemble_quality_metrics(metric_name);

-- 13. ADD MISSING COLUMNS TO AGENT_SIGNALS
ALTER TABLE agent_signals ADD COLUMN IF NOT EXISTS predicted_direction VARCHAR(20);
ALTER TABLE agent_signals ADD COLUMN IF NOT EXISTS actual_direction VARCHAR(20);

-- 14. ADD MISSING COLUMNS TO PREDICTIONS
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS predicted_direction VARCHAR(20);
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS actual_direction VARCHAR(20);

-- 15. RAG_NEWS_DOCUMENTS (recreate with correct schema)
DROP TABLE IF EXISTS rag_news_documents CASCADE;
CREATE TABLE rag_news_documents (
    id SERIAL PRIMARY KEY,
    doc_id VARCHAR(255) UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    source VARCHAR(100),
    url TEXT,
    category VARCHAR(50),
    tags TEXT[] DEFAULT '{}',
    published_at TIMESTAMP,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_rag_news_doc_id ON rag_news_documents(doc_id);
CREATE INDEX idx_rag_news_source ON rag_news_documents(source);
CREATE INDEX idx_rag_news_published ON rag_news_documents(published_at);

-- 16. RL_PERFORMANCE_METRICS - add unique constraint
DO $$
BEGIN
    -- Delete duplicates first
    DELETE FROM rl_performance_metrics a
    USING rl_performance_metrics b
    WHERE a.id < b.id AND a.measurement_period = b.measurement_period;

    -- Add unique constraint if not exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'rl_performance_metrics_period_unique'
    ) THEN
        ALTER TABLE rl_performance_metrics ADD CONSTRAINT rl_performance_metrics_period_unique UNIQUE (measurement_period);
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not add rl_performance_metrics constraint: %', SQLERRM;
END $$;

-- 17. Remove foreign key constraint from rl_actions (to allow BTC-USD etc)
ALTER TABLE rl_actions DROP CONSTRAINT IF EXISTS fk_rl_actions_symbol;

-- =====================================================
-- LOG COMPLETION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Migration v4.21 COMPLETE - All tables fixed!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Fixed tables:';
    RAISE NOTICE '  - meta_agent_performance';
    RAISE NOTICE '  - meta_agent_rankings';
    RAISE NOTICE '  - meta_regime_analysis';
    RAISE NOTICE '  - meta_rotation_decisions';
    RAISE NOTICE '  - latent_market_data';
    RAISE NOTICE '  - latent_patterns';
    RAISE NOTICE '  - latent_compression_metrics';
    RAISE NOTICE '  - latent_pattern_insights';
    RAISE NOTICE '  - ensemble_agent_signals';
    RAISE NOTICE '  - ensemble_agent_weights';
    RAISE NOTICE '  - ensemble_signals';
    RAISE NOTICE '  - ensemble_quality_metrics';
    RAISE NOTICE '  - rag_news_documents';
    RAISE NOTICE 'Added columns:';
    RAISE NOTICE '  - agent_signals.predicted_direction';
    RAISE NOTICE '  - agent_signals.actual_direction';
    RAISE NOTICE '  - predictions.predicted_direction';
    RAISE NOTICE '  - predictions.actual_direction';
    RAISE NOTICE 'Removed constraints:';
    RAISE NOTICE '  - rl_actions.fk_rl_actions_symbol (allows BTC-USD)';
    RAISE NOTICE '=====================================================';
END $$;
