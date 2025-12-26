CREATE OR REPLACE VIEW AI_CLASSIFIED_FINDINGS AS
SELECT
    f.FINDING_ID,
    r.PROPERTY_ID,
    f.ROOM_ID,
    f.FINDING_TEXT,
    f.INSPECTION_TIME,
    f.image_label as ORIGINAL_LABEL,
    f.severity as ORIGINAL_SEVERITY,
    f.estimated_repair_cost as ORIGINAL_COST,
    
    -- REAL AI: Cortex classification
    TRIM(LOWER(
        SNOWFLAKE.CORTEX.COMPLETE(
            'llama3.1-8b',
            CONCAT(
                'Classify this house inspection finding into ONE category. ',
                'Respond with ONLY one word: leak, crack, wiring, structural, or ok. ',
                'No explanation. Finding: ', f.FINDING_TEXT
            )
        )
    )) AS AI_RAW_LABEL,
    
    -- REAL AI: Cortex severity detection
    TRIM(UPPER(
        SNOWFLAKE.CORTEX.COMPLETE(
            'llama3.1-8b',
            CONCAT(
                'Rate severity as ONE word only: critical, high, medium, or low. ',
                'No explanation. Issue: ', f.FINDING_TEXT
            )
        )
    )) AS AI_RAW_SEVERITY,
    
    -- REAL AI: Sentiment analysis
    SNOWFLAKE.CORTEX.SENTIMENT(f.FINDING_TEXT) AS AI_SENTIMENT_SCORE,
    
    'CORTEX_AI_POWERED' AS AI_MODE

FROM INSPECTION_FINDINGS f
JOIN ROOMS r ON f.ROOM_ID = r.ROOM_ID;

-- =====================================================
-- STEP 4: CLEAN AI RESPONSES & ADD INSIGHTS
-- =====================================================

CREATE OR REPLACE VIEW AI_DEFECT_INSIGHTS AS
SELECT
    FINDING_ID,
    PROPERTY_ID,
    ROOM_ID,
    FINDING_TEXT,
    ORIGINAL_LABEL,
    ORIGINAL_SEVERITY,
    
    -- Clean AI label response
    CASE
        WHEN AI_RAW_LABEL LIKE '%leak%' THEN 'leak'
        WHEN AI_RAW_LABEL LIKE '%crack%' THEN 'crack'
        WHEN AI_RAW_LABEL LIKE '%wiring%' OR AI_RAW_LABEL LIKE '%wire%' THEN 'wiring'
        WHEN AI_RAW_LABEL LIKE '%structural%' OR AI_RAW_LABEL LIKE '%structure%' THEN 'structural'
        WHEN AI_RAW_LABEL LIKE '%ok%' THEN 'ok'
        ELSE ORIGINAL_LABEL
    END AS AI_DEFECT_LABEL,
    
    -- Clean AI severity response
    CASE
        WHEN AI_RAW_SEVERITY LIKE '%CRITICAL%' THEN 'CRITICAL'
        WHEN AI_RAW_SEVERITY LIKE '%HIGH%' THEN 'HIGH'
        WHEN AI_RAW_SEVERITY LIKE '%MEDIUM%' THEN 'MEDIUM'
        WHEN AI_RAW_SEVERITY LIKE '%LOW%' THEN 'LOW'
        ELSE 'MEDIUM'
    END AS AI_SEVERITY,
    
    AI_SENTIMENT_SCORE,
    
    -- AI-powered repair cost
    CASE
        WHEN AI_RAW_SEVERITY LIKE '%CRITICAL%' THEN 100000
        WHEN AI_RAW_LABEL LIKE '%leak%' AND AI_RAW_SEVERITY LIKE '%HIGH%' THEN 50000
        WHEN AI_RAW_LABEL LIKE '%wiring%' AND AI_RAW_SEVERITY LIKE '%HIGH%' THEN 40000
        WHEN AI_RAW_LABEL LIKE '%structural%' THEN 80000
        WHEN AI_RAW_LABEL LIKE '%crack%' THEN 15000
        WHEN AI_RAW_LABEL LIKE '%ok%' THEN 0
        ELSE 5000
    END AS AI_ESTIMATED_REPAIR_COST,
    
    -- AI confidence score
    CASE
        WHEN ABS(AI_SENTIMENT_SCORE) > 0.7 THEN 95
        WHEN ABS(AI_SENTIMENT_SCORE) > 0.5 THEN 85
        WHEN ABS(AI_SENTIMENT_SCORE) > 0.3 THEN 75
        ELSE 65
    END AS AI_CONFIDENCE_SCORE,
    
    INSPECTION_TIME,
    AI_MODE

FROM AI_CLASSIFIED_FINDINGS;
