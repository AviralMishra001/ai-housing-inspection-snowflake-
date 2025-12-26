-- STEP 8: STREAMS & TASKS
-- =====================================================

CREATE OR REPLACE STREAM INSPECTION_FINDINGS_STREAM
ON TABLE INSPECTION_FINDINGS
APPEND_ONLY = FALSE;

CREATE OR REPLACE TABLE INSPECTION_REFRESH_LOG (
  refresh_time TIMESTAMP,
  affected_rows NUMBER,
  note STRING
);

CREATE OR REPLACE TASK INSPECTION_REFRESH_TASK
WAREHOUSE = INSPECTION_WH
SCHEDULE = '5 MINUTE'
AS
INSERT INTO INSPECTION_REFRESH_LOG
SELECT
  CURRENT_TIMESTAMP,
  COUNT(*),
  'New inspection findings processed by AI'
FROM INSPECTION_FINDINGS_STREAM
WHERE METADATA$ACTION = 'INSERT';

ALTER TASK INSPECTION_REFRESH_TASK RESUME;

-- =====================================================
-- STEP 9: STREAMLIT DASHBOARD VIEW
-- =====================================================

CREATE OR REPLACE VIEW STREAMLIT_DASHBOARD_VIEW AS
SELECT
    prs.PROPERTY_ID,
    prs.PROPERTY_NAME,
    prs.CITY,
    prs.RISK_LEVEL,
    prs.RISK_SCORE,
    prs.TOTAL_ISSUES,
    prs.TOTAL_ESTIMATED_REPAIR_COST,
    prs.LAST_INSPECTION_TIME,
    prs.RECOMMENDED_ACTION,
    pas.AI_SUMMARY,
    'CORTEX_AI_POWERED' as CLASSIFICATION_METHOD
FROM PROPERTY_RISK_SUMMARY prs
LEFT JOIN PROPERTY_AI_SUMMARY pas 
    ON prs.PROPERTY_ID = pas.PROPERTY_ID
ORDER BY prs.RISK_SCORE DESC;

-- VERIFICATION - Check Everything Works
-- =====================================================

-- 1. Check AI classification
SELECT 
    FINDING_TEXT,
    ORIGINAL_LABEL,
    AI_DEFECT_LABEL,
    AI_SEVERITY,
    AI_CONFIDENCE_SCORE,
    AI_MODE
FROM AI_DEFECT_INSIGHTS;

-- 2. Check room risks
SELECT * FROM ROOM_RISK_VIEW;

-- 3. Check property risks
SELECT * FROM PROPERTY_RISK_SUMMARY;

-- 4. Check AI summaries
SELECT PROPERTY_NAME, AI_SUMMARY FROM PROPERTY_AI_SUMMARY;

-- 5. Check final dashboard view
SELECT * FROM STREAMLIT_DASHBOARD_VIEW;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
    '✅ Complete AI Housing Inspection System Ready!' AS STATUS,
    'Using Snowflake Cortex llama3.1-8b for real AI classification' AS AI_ENGINE;
