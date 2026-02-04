-- Migration v4.19: Add missing tables for AI Market Analysis System
-- Run this after init.sql to add tables required by new services

-- =====================================================
-- ENSEMBLE BLENDER TABLES
-- =====================================================

-- Create ensemble_signals table for storing blended signals
CREATE TABLE IF NOT EXISTS ensemble_signals (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    signal_type VARCHAR(20) NOT NULL CHECK (signal_type IN ('buy', 'sell', 'hold', 'strong_buy', 'strong_sell')),
    confidence DECIMAL(5,4) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
    blended_score DECIMAL(8,4) NOT NULL,
    contributing_agents TEXT[] NOT NULL DEFAULT '{}',
    agent_weights JSONB NOT NULL DEFAULT '{}',
    reasoning TEXT,
    market_regime VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ensemble_agent_weights table for tracking agent weights in ensemble
CREATE TABLE IF NOT EXISTS ensemble_agent_weights (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    weight DECIMAL(5,4) NOT NULL CHECK (weight BETWEEN 0 AND 1),
    performance_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    regime_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    recency_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    volatility_adjustment DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    final_weight DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    calculation_method VARCHAR(50) NOT NULL DEFAULT 'adaptive',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(agent_name, created_at)
);

-- Create indexes for ensemble tables
CREATE INDEX IF NOT EXISTS idx_ensemble_signals_symbol ON ensemble_signals(symbol);
CREATE INDEX IF NOT EXISTS idx_ensemble_signals_created_at ON ensemble_signals(created_at);
CREATE INDEX IF NOT EXISTS idx_ensemble_signals_signal_type ON ensemble_signals(signal_type);
CREATE INDEX IF NOT EXISTS idx_ensemble_agent_weights_agent ON ensemble_agent_weights(agent_name);
CREATE INDEX IF NOT EXISTS idx_ensemble_agent_weights_created_at ON ensemble_agent_weights(created_at);

-- =====================================================
-- META EVALUATION TABLES
-- =====================================================

-- Create meta_agent_performance table for meta-level agent evaluation
CREATE TABLE IF NOT EXISTS meta_agent_performance (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    evaluation_period VARCHAR(20) NOT NULL DEFAULT '7d',
    total_predictions INTEGER NOT NULL DEFAULT 0,
    correct_predictions INTEGER NOT NULL DEFAULT 0,
    accuracy DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    precision_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    recall_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    f1_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    sharpe_ratio DECIMAL(8,4) NOT NULL DEFAULT 0.0,
    sortino_ratio DECIMAL(8,4) NOT NULL DEFAULT 0.0,
    max_drawdown DECIMAL(8,4) NOT NULL DEFAULT 0.0,
    win_rate DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    profit_factor DECIMAL(8,4) NOT NULL DEFAULT 0.0,
    avg_profit DECIMAL(10,4) NOT NULL DEFAULT 0.0,
    avg_loss DECIMAL(10,4) NOT NULL DEFAULT 0.0,
    consistency_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    regime_adaptability DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    overall_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    rank INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(agent_name, evaluation_period, created_at)
);

-- Create meta_agent_rankings table for storing periodic rankings
CREATE TABLE IF NOT EXISTS meta_agent_rankings (
    id SERIAL PRIMARY KEY,
    ranking_period VARCHAR(20) NOT NULL DEFAULT 'daily',
    agent_name VARCHAR(100) NOT NULL,
    rank INTEGER NOT NULL,
    score DECIMAL(5,4) NOT NULL,
    score_change DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    rank_change INTEGER NOT NULL DEFAULT 0,
    performance_tier VARCHAR(20) NOT NULL DEFAULT 'standard' CHECK (performance_tier IN ('top', 'above_average', 'standard', 'below_average', 'bottom')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ranking_period, agent_name, created_at)
);

-- Create meta_regime_analysis table for market regime analysis
CREATE TABLE IF NOT EXISTS meta_regime_analysis (
    id SERIAL PRIMARY KEY,
    regime_type VARCHAR(50) NOT NULL,
    regime_confidence DECIMAL(5,4) NOT NULL,
    volatility_level VARCHAR(20) NOT NULL CHECK (volatility_level IN ('low', 'medium', 'high', 'extreme')),
    trend_direction VARCHAR(20) NOT NULL CHECK (trend_direction IN ('bullish', 'bearish', 'neutral', 'mixed')),
    trend_strength DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    market_breadth DECIMAL(5,4),
    sector_rotation JSONB DEFAULT '{}',
    leading_sectors TEXT[] DEFAULT '{}',
    lagging_sectors TEXT[] DEFAULT '{}',
    risk_level VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (risk_level IN ('low', 'medium', 'high', 'extreme')),
    recommended_allocation JSONB DEFAULT '{}',
    analysis_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create meta_rotation_decisions table for agent rotation tracking
CREATE TABLE IF NOT EXISTS meta_rotation_decisions (
    id SERIAL PRIMARY KEY,
    decision_type VARCHAR(50) NOT NULL CHECK (decision_type IN ('promote', 'demote', 'maintain', 'suspend', 'reactivate')),
    agent_name VARCHAR(100) NOT NULL,
    previous_tier VARCHAR(20),
    new_tier VARCHAR(20),
    reason TEXT NOT NULL,
    performance_metrics JSONB NOT NULL DEFAULT '{}',
    triggered_by VARCHAR(100) NOT NULL DEFAULT 'automatic',
    is_applied BOOLEAN NOT NULL DEFAULT FALSE,
    applied_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for meta evaluation tables
CREATE INDEX IF NOT EXISTS idx_meta_agent_performance_agent ON meta_agent_performance(agent_name);
CREATE INDEX IF NOT EXISTS idx_meta_agent_performance_created ON meta_agent_performance(created_at);
CREATE INDEX IF NOT EXISTS idx_meta_agent_rankings_period ON meta_agent_rankings(ranking_period);
CREATE INDEX IF NOT EXISTS idx_meta_agent_rankings_rank ON meta_agent_rankings(rank);
CREATE INDEX IF NOT EXISTS idx_meta_regime_analysis_regime ON meta_regime_analysis(regime_type);
CREATE INDEX IF NOT EXISTS idx_meta_regime_analysis_created ON meta_regime_analysis(created_at);
CREATE INDEX IF NOT EXISTS idx_meta_rotation_decisions_agent ON meta_rotation_decisions(agent_name);
CREATE INDEX IF NOT EXISTS idx_meta_rotation_decisions_type ON meta_rotation_decisions(decision_type);

-- =====================================================
-- LATENT PATTERN TABLES
-- =====================================================

-- Create latent_market_data table for storing market data snapshots
CREATE TABLE IF NOT EXISTS latent_market_data (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    open_price DECIMAL(15,4) NOT NULL,
    high_price DECIMAL(15,4) NOT NULL,
    low_price DECIMAL(15,4) NOT NULL,
    close_price DECIMAL(15,4) NOT NULL,
    volume BIGINT NOT NULL,
    vwap DECIMAL(15,4),
    rsi DECIMAL(5,2),
    macd DECIMAL(10,4),
    macd_signal DECIMAL(10,4),
    macd_histogram DECIMAL(10,4),
    bollinger_upper DECIMAL(15,4),
    bollinger_middle DECIMAL(15,4),
    bollinger_lower DECIMAL(15,4),
    atr DECIMAL(10,4),
    obv BIGINT,
    adx DECIMAL(5,2),
    cci DECIMAL(8,2),
    stochastic_k DECIMAL(5,2),
    stochastic_d DECIMAL(5,2),
    raw_features JSONB DEFAULT '{}',
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create latent_patterns table for detected patterns
CREATE TABLE IF NOT EXISTS latent_patterns (
    id SERIAL PRIMARY KEY,
    pattern_id VARCHAR(100) UNIQUE NOT NULL,
    pattern_type VARCHAR(50) NOT NULL,
    pattern_name VARCHAR(100) NOT NULL,
    symbols TEXT[] NOT NULL DEFAULT '{}',
    confidence DECIMAL(5,4) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
    strength DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    duration_days INTEGER NOT NULL DEFAULT 1,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    features JSONB NOT NULL DEFAULT '{}',
    model_output JSONB DEFAULT '{}',
    prediction JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create latent_pattern_signals table for pattern-based signals
CREATE TABLE IF NOT EXISTS latent_pattern_signals (
    id SERIAL PRIMARY KEY,
    pattern_id VARCHAR(100) NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    signal_type VARCHAR(20) NOT NULL CHECK (signal_type IN ('buy', 'sell', 'hold')),
    confidence DECIMAL(5,4) NOT NULL,
    expected_return DECIMAL(8,4),
    risk_score DECIMAL(5,4),
    time_horizon VARCHAR(20) DEFAULT 'short_term',
    reasoning TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_latent_signals_pattern
        FOREIGN KEY (pattern_id) REFERENCES latent_patterns(pattern_id) ON DELETE CASCADE
);

-- Create indexes for latent pattern tables
CREATE INDEX IF NOT EXISTS idx_latent_market_data_symbol ON latent_market_data(symbol);
CREATE INDEX IF NOT EXISTS idx_latent_market_data_timestamp ON latent_market_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_latent_patterns_type ON latent_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_latent_patterns_active ON latent_patterns(is_active);
CREATE INDEX IF NOT EXISTS idx_latent_patterns_created ON latent_patterns(created_at);
CREATE INDEX IF NOT EXISTS idx_latent_pattern_signals_pattern ON latent_pattern_signals(pattern_id);
CREATE INDEX IF NOT EXISTS idx_latent_pattern_signals_symbol ON latent_pattern_signals(symbol);

-- =====================================================
-- PREDICTIONS TABLE MODIFICATIONS
-- =====================================================

-- Create predictions table if not exists
CREATE TABLE IF NOT EXISTS predictions (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    agent_name VARCHAR(100) NOT NULL,
    prediction_type VARCHAR(50) NOT NULL,
    predicted_value DECIMAL(15,4),
    predicted_direction VARCHAR(20) CHECK (predicted_direction IN ('up', 'down', 'neutral')),
    confidence DECIMAL(5,4) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
    time_horizon VARCHAR(20) NOT NULL DEFAULT 'short_term',
    actual_value DECIMAL(15,4),
    actual_direction VARCHAR(20),
    is_correct BOOLEAN,
    error_margin DECIMAL(10,4),
    features_used JSONB DEFAULT '{}',
    model_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    evaluated_at TIMESTAMP
);

-- Add predicted_direction column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'predictions' AND column_name = 'predicted_direction'
    ) THEN
        ALTER TABLE predictions ADD COLUMN predicted_direction VARCHAR(20) CHECK (predicted_direction IN ('up', 'down', 'neutral'));
    END IF;
END $$;

-- Create indexes for predictions
CREATE INDEX IF NOT EXISTS idx_predictions_symbol ON predictions(symbol);
CREATE INDEX IF NOT EXISTS idx_predictions_agent ON predictions(agent_name);
CREATE INDEX IF NOT EXISTS idx_predictions_created ON predictions(created_at);
CREATE INDEX IF NOT EXISTS idx_predictions_direction ON predictions(predicted_direction);

-- =====================================================
-- RL PERFORMANCE METRICS UNIQUE CONSTRAINT
-- =====================================================

-- Add unique constraint to rl_performance_metrics for ON CONFLICT
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'rl_performance_metrics_period_created_unique'
    ) THEN
        ALTER TABLE rl_performance_metrics
        ADD CONSTRAINT rl_performance_metrics_period_created_unique
        UNIQUE (measurement_period, created_at);
    END IF;
END $$;

-- =====================================================
-- KOREAN MARKET SUPPORT TABLES
-- =====================================================

-- Create kr_symbols table for Korean market symbols
CREATE TABLE IF NOT EXISTS kr_symbols (
    ticker VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    market VARCHAR(20) NOT NULL CHECK (market IN ('KOSPI', 'KOSDAQ')),
    sector VARCHAR(100),
    industry VARCHAR(100),
    market_cap BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create kr_price_history table for Korean stock prices
CREATE TABLE IF NOT EXISTS kr_price_history (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(20) NOT NULL,
    open_price DECIMAL(15,2) NOT NULL,
    high_price DECIMAL(15,2) NOT NULL,
    low_price DECIMAL(15,2) NOT NULL,
    close_price DECIMAL(15,2) NOT NULL,
    volume BIGINT NOT NULL,
    change_percent DECIMAL(8,4),
    trading_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_kr_price_ticker
        FOREIGN KEY (ticker) REFERENCES kr_symbols(ticker) ON DELETE CASCADE,
    UNIQUE(ticker, trading_date)
);

-- Create indexes for Korean market tables
CREATE INDEX IF NOT EXISTS idx_kr_symbols_market ON kr_symbols(market);
CREATE INDEX IF NOT EXISTS idx_kr_symbols_name ON kr_symbols(name);
CREATE INDEX IF NOT EXISTS idx_kr_price_history_ticker ON kr_price_history(ticker);
CREATE INDEX IF NOT EXISTS idx_kr_price_history_date ON kr_price_history(trading_date);

-- =====================================================
-- TRIGGER UPDATES
-- =====================================================

-- Add updated_at trigger for new tables
DROP TRIGGER IF EXISTS update_ensemble_agent_weights_updated_at ON ensemble_agent_weights;
CREATE TRIGGER update_ensemble_agent_weights_updated_at
    BEFORE UPDATE ON ensemble_agent_weights
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_latent_patterns_updated_at ON latent_patterns;
CREATE TRIGGER update_latent_patterns_updated_at
    BEFORE UPDATE ON latent_patterns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_kr_symbols_updated_at ON kr_symbols;
CREATE TRIGGER update_kr_symbols_updated_at
    BEFORE UPDATE ON kr_symbols
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- LOG COMPLETION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Migration v4.19 completed successfully!';
    RAISE NOTICE 'Added tables: ensemble_signals, ensemble_agent_weights';
    RAISE NOTICE 'Added tables: meta_agent_performance, meta_agent_rankings, meta_regime_analysis, meta_rotation_decisions';
    RAISE NOTICE 'Added tables: latent_market_data, latent_patterns, latent_pattern_signals';
    RAISE NOTICE 'Added tables: predictions (if not exists), kr_symbols, kr_price_history';
    RAISE NOTICE 'Added column: predicted_direction to predictions table';
    RAISE NOTICE 'Added constraint: rl_performance_metrics_period_created_unique';
END $$;
