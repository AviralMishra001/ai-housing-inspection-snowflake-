
-- STEP 5: ROOM-LEVEL RISK AGGREGATION

CREATE OR REPLACE VIEW ROOM_RISK_VIEW AS
SELECT
    r.ROOM_ID,
    r.ROOM_NAME,
    p.PROPERTY_NAME,
    p.PROPERTY_ID,
    
    COUNT(ai.FINDING_ID) AS ISSUE_COUNT,
    
    -- Room risk score from AI
    SUM(
        CASE ai.AI_SEVERITY
            WHEN 'CRITICAL' THEN 5
            WHEN 'HIGH' THEN 3
            WHEN 'MEDIUM' THEN 2
            WHEN 'LOW' THEN 1
            ELSE 0
        END
    ) AS ROOM_RISK_SCORE,
    
    -- AI-detected issue types
    LISTAGG(DISTINCT ai.AI_DEFECT_LABEL, ', ') 
        WITHIN GROUP (ORDER BY ai.AI_DEFECT_LABEL) AS ISSUE_TYPES,
    
    -- Total repair cost
    SUM(ai.AI_ESTIMATED_REPAIR_COST) AS ROOM_REPAIR_COST,
    
    -- Average AI confidence
    ROUND(AVG(ai.AI_CONFIDENCE_SCORE), 0) AS AVG_AI_CONFIDENCE

FROM PROPERTIES p
JOIN ROOMS r ON p.PROPERTY_ID = r.PROPERTY_ID
LEFT JOIN AI_DEFECT_INSIGHTS ai ON r.ROOM_ID = ai.ROOM_ID
GROUP BY r.ROOM_ID, r.ROOM_NAME, p.PROPERTY_NAME, p.PROPERTY_ID;

-- =====================================================
-- STEP 6: PROPERTY-LEVEL RISK SUMMARY
-- =====================================================

CREATE OR REPLACE VIEW PROPERTY_RISK_SUMMARY AS
SELECT
    p.PROPERTY_ID,
    p.PROPERTY_NAME,
    p.CITY,
    
    COUNT(ai.FINDING_ID) AS TOTAL_ISSUES,
    
    -- Overall AI risk score
    SUM(
        CASE ai.AI_SEVERITY
            WHEN 'CRITICAL' THEN 5
            WHEN 'HIGH' THEN 3
            WHEN 'MEDIUM' THEN 2
            WHEN 'LOW' THEN 1
            ELSE 0
        END
    ) AS RISK_SCORE,
    
    -- AI-estimated total repair cost
    SUM(ai.AI_ESTIMATED_REPAIR_COST) AS TOTAL_ESTIMATED_REPAIR_COST,
    
    -- Latest inspection
    MAX(ai.INSPECTION_TIME) AS LAST_INSPECTION_TIME,
    
    -- Risk level from AI
    CASE
        WHEN SUM(CASE ai.AI_SEVERITY
            WHEN 'CRITICAL' THEN 5 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END) >= 20 THEN 'HIGH'
        WHEN SUM(CASE ai.AI_SEVERITY
            WHEN 'CRITICAL' THEN 5 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END) >= 10 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS RISK_LEVEL,
    
    -- AI-powered recommendation
    CASE
        WHEN SUM(CASE ai.AI_SEVERITY
            WHEN 'CRITICAL' THEN 5 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END) >= 20 
            THEN 'Immediate inspection and repair required'
        WHEN SUM(CASE ai.AI_SEVERITY
            WHEN 'CRITICAL' THEN 5 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END) >= 10 
            THEN 'Plan repairs within 30 days'
        ELSE 'Routine monitoring'
    END AS RECOMMENDED_ACTION

FROM PROPERTIES p
LEFT JOIN ROOMS r ON p.PROPERTY_ID = r.PROPERTY_ID
LEFT JOIN AI_DEFECT_INSIGHTS ai ON r.ROOM_ID = ai.ROOM_ID
GROUP BY p.PROPERTY_ID, p.PROPERTY_NAME, p.CITY;

-- =====================================================
-- STEP 7: CORTEX AI-GENERATED SUMMARIES
-- =====================================================

CREATE OR REPLACE VIEW PROPERTY_AI_SUMMARY AS
SELECT
    p.PROPERTY_ID,
    p.PROPERTY_NAME,
    
    -- Use Cortex to generate natural language summary
    SNOWFLAKE.CORTEX.COMPLETE(
        'llama3.1-8b',
        CONCAT(
            'Write a 2-3 sentence safety report for this property inspection. ',
            'Focus on risks and urgency for families. Findings: ',
            LISTAGG(
                CONCAT(r.ROOM_NAME, ' - ', ai.AI_DEFECT_LABEL, ' (', ai.AI_SEVERITY, ')'),
                ', '
            ) WITHIN GROUP (ORDER BY ai.AI_SEVERITY DESC)
        )
    ) AS AI_SUMMARY,
    
    COUNT(ai.FINDING_ID) as TOTAL_AI_DETECTIONS,
    
    -- Count by AI-detected type
    SUM(CASE WHEN ai.AI_DEFECT_LABEL = 'leak' THEN 1 ELSE 0 END) as AI_LEAK_COUNT,
    SUM(CASE WHEN ai.AI_DEFECT_LABEL = 'wiring' THEN 1 ELSE 0 END) as AI_WIRING_COUNT,
    SUM(CASE WHEN ai.AI_DEFECT_LABEL = 'crack' THEN 1 ELSE 0 END) as AI_CRACK_COUNT

FROM PROPERTIES p
LEFT JOIN ROOMS r ON p.PROPERTY_ID = r.PROPERTY_ID
LEFT JOIN AI_DEFECT_INSIGHTS ai ON r.ROOM_ID = ai.ROOM_ID
WHERE ai.AI_DEFECT_LABEL != 'ok' OR ai.AI_DEFECT_LABEL IS NULL
GROUP BY p.PROPERTY_ID, p.PROPERTY_NAME;
