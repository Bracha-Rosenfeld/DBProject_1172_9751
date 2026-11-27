-- Index performance experiment for PostgreSQL.
-- Run this file once on the populated database. The first three plans are the
-- baseline (before the indexes); the last three plans are after index creation.
-- EXPLAIN ANALYZE executes each SELECT and reports actual execution time.

-- Keep planner statistics current before measuring the baseline.
ANALYZE dispense_log;
ANALYZE blood_inventory;

-- Baseline 1: look up dispense records for a request.
-- Supports pending-request checks and request/dispense joins.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM dispense_log
WHERE request_id = 1;

-- Baseline 2: find the dispense record for a blood unit.
-- Supports donor dispense history and checks for already-dispensed units.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM dispense_log
WHERE unit_id = 'UNIT-100001';

-- Baseline 3: find available units expiring in the next seven days.
-- This matches the inventory expiration alert used by the application.
EXPLAIN (ANALYZE, BUFFERS)
SELECT unit_id, expiration_date
FROM blood_inventory
WHERE status = 'Available'
  AND expiration_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY expiration_date;


-- Index 1: accelerates checks and joins by blood request.
CREATE INDEX idx_dispense_log_request_id
    ON dispense_log (request_id);

-- Index 2: accelerates lookups and joins by blood unit.
CREATE INDEX idx_dispense_log_unit_id
    ON dispense_log (unit_id);

-- Index 3: a smaller partial index for the expiration alert.
-- Non-available units are excluded, reducing index size and write overhead.
CREATE INDEX idx_blood_inventory_available_expiration
    ON blood_inventory (expiration_date)
    WHERE status = 'Available';

-- Refresh statistics so the planner can consider the newly created indexes.
ANALYZE dispense_log;
ANALYZE blood_inventory;

-- After-index measurements: run the same queries and compare their plans,
-- Execution Time, and shared buffer reads/hits with the baseline above.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM dispense_log
WHERE request_id = 1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM dispense_log
WHERE unit_id = 'UNIT-100001';

EXPLAIN (ANALYZE, BUFFERS)
SELECT unit_id, expiration_date
FROM blood_inventory
WHERE status = 'Available'
  AND expiration_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY expiration_date;