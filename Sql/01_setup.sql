USE WAREHOUSE INSPECTION_WH;
USE DATABASE HOUSING_INSPECTION;
USE SCHEMA CORE;

CREATE OR REPLACE TABLE PROPERTIES (
  property_id STRING,
  property_name STRING,
  city STRING,
  inspection_date DATE
);

CREATE OR REPLACE TABLE ROOMS (
  room_id STRING,
  property_id STRING,
  room_name STRING
);

CREATE OR REPLACE TABLE INSPECTION_FINDINGS (
  finding_id STRING,
  room_id STRING,
  finding_text STRING,
  image_label STRING,
  severity STRING,
  inspection_time TIMESTAMP,
  estimated_repair_cost NUMBER
);

-- =====================================================
-- STEP 2: INSERT SAMPLE DATA
-- =====================================================

INSERT INTO PROPERTIES VALUES
('P1', 'Green View Apartments', 'Delhi', '2025-01-10');

INSERT INTO ROOMS VALUES
('R1', 'P1', 'Living Room'),
('R2', 'P1', 'Kitchen'),
('R3', 'P1', 'Bedroom');

INSERT INTO INSPECTION_FINDINGS VALUES
('F1','R1','Damp patch near ceiling','leak','high','2025-01-10 10:00', 50000),
('F2','R2','Exposed electrical wires','wiring','high','2025-01-10 10:15', 40000),
('F3','R3','Small wall crack','crack','medium','2025-01-10 10:30', 15000),
('F4','R3','Room looks fine','ok','low','2025-01-10 10:45', 0);
