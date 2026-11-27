-- Query 1: Retrieve detailed dispense records for 'Stat' urgency requests, ordered by year and month.

-- use JOIN
SELECT 
    EXTRACT(YEAR FROM dl.dispense_date) AS dispense_year,
    EXTRACT(MONTH FROM dl.dispense_date) AS dispense_month,
    w.ward_name,
    br.patient_name,
    bi.unit_id,
    bi.component_type,
    s.first_name || ' ' || s.last_name AS staff_name
FROM dispense_log dl
JOIN blood_requests br ON dl.request_id = br.request_id
JOIN wards w ON br.ward_id = w.ward_id
JOIN blood_inventory bi ON dl.unit_id = bi.unit_id
JOIN staff s ON dl.staff_id = s.staff_id
WHERE br.urgency_level = 'Stat'
ORDER BY dispense_year DESC, dispense_month DESC;

-- use IN:
SELECT 
    EXTRACT(YEAR FROM dl.dispense_date) AS dispense_year,
    EXTRACT(MONTH FROM dl.dispense_date) AS dispense_month,
    w.ward_name,
    br.patient_name,
    bi.unit_id,
    bi.component_type,
    s.first_name || ' ' || s.last_name AS staff_name
FROM dispense_log dl
JOIN blood_requests br ON dl.request_id = br.request_id
JOIN wards w ON br.ward_id = w.ward_id
JOIN blood_inventory bi ON dl.unit_id = bi.unit_id
JOIN staff s ON dl.staff_id = s.staff_id
WHERE dl.request_id IN (
    SELECT request_id 
    FROM blood_requests 
    WHERE urgency_level = 'Stat'
)
ORDER BY dispense_year DESC, dispense_month DESC;

-- Query 2: List donors whose donated blood units have been dispensed to hospital wards.

-- use EXISTS:
SELECT 
    d.donor_id,
    d.first_name || ' ' || d.last_name AS donor_name,
    d.blood_type || d.rh_factor AS full_blood_type,
    EXTRACT(YEAR FROM d.last_donation_date) AS last_year,
    EXTRACT(MONTH FROM d.last_donation_date) AS last_month
FROM donor d
WHERE EXISTS (
    SELECT 1
    FROM blood_inventory bi
    JOIN dispense_log dl ON bi.unit_id = dl.unit_id
    WHERE bi.donor_id = d.donor_id
)
ORDER BY last_year DESC, last_month DESC;

-- use DISTINCT and JOIN:
SELECT DISTINCT
    d.donor_id,
    d.first_name || ' ' || d.last_name AS donor_name,
    d.blood_type || d.rh_factor AS full_blood_type,
    EXTRACT(YEAR FROM d.last_donation_date) AS last_year,
    EXTRACT(MONTH FROM d.last_donation_date) AS last_month
FROM donor d
JOIN blood_inventory bi ON d.donor_id = bi.donor_id
JOIN dispense_log dl ON bi.unit_id = dl.unit_id
ORDER BY last_year DESC, last_month DESC;

-- Query 3: Identify pending blood requests that have no associated dispense records yet.

-- use LEFT JOIN and IS NULL:
SELECT 
    br.request_id,
    w.ward_name,
    br.patient_name,
    br.requested_blood_type || br.requested_rh AS needed_type,
    br.urgency_level,
    EXTRACT(DAY FROM br.requested_date) AS req_day,
    EXTRACT(MONTH FROM br.requested_date) AS req_month
FROM blood_requests br
JOIN wards w ON br.ward_id = w.ward_id
LEFT JOIN dispense_log dl ON br.request_id = dl.request_id
WHERE dl.dispense_id IS NULL
ORDER BY br.requested_date ASC;

-- use NOT EXISTS:
SELECT 
    br.request_id,
    w.ward_name,
    br.patient_name,
    br.requested_blood_type || br.requested_rh AS needed_type,
    br.urgency_level,
    EXTRACT(DAY FROM br.requested_date) AS req_day,
    EXTRACT(MONTH FROM br.requested_date) AS req_month
FROM blood_requests br
JOIN wards w ON br.ward_id = w.ward_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM dispense_log dl 
    WHERE dl.request_id = br.request_id
)
ORDER BY br.requested_date ASC;

-- Query 4: Find available blood units with hemoglobin levels above the average for their component type.

-- use WHERE:
SELECT 
    bi.unit_id,
    bi.component_type,
    d.blood_type || d.rh_factor AS blood_group,
    bi.hemoglobin,
    bi.expiration_date
FROM blood_inventory bi
JOIN donor d ON bi.donor_id = d.donor_id
WHERE bi.status = 'Available'
  AND bi.hemoglobin > (
      SELECT AVG(bi2.hemoglobin)
      FROM blood_inventory bi2
      WHERE bi2.component_type = bi.component_type
  )
ORDER BY bi.hemoglobin DESC;

-- use JOIN with GROUP BY:
SELECT 
    bi.unit_id,
    bi.component_type,
    d.blood_type || d.rh_factor AS blood_group,
    bi.hemoglobin,
    bi.expiration_date
FROM blood_inventory bi
JOIN donor d ON bi.donor_id = d.donor_id
JOIN (
    SELECT component_type, AVG(hemoglobin) AS avg_hb
    FROM blood_inventory
    GROUP BY component_type
) avg_tbl ON bi.component_type = avg_tbl.component_type
WHERE bi.status = 'Available'
  AND bi.hemoglobin > avg_tbl.avg_hb
ORDER BY bi.hemoglobin DESC;

-- Query 5: Summarize available blood inventory by blood group and component type, highlighting potential shortages.
SELECT 
    d.blood_type || d.rh_factor AS blood_group,
    bi.component_type,
    COUNT(bi.unit_id) AS available_units,
    ROUND(AVG(bi.hemoglobin), 2) AS avg_hemoglobin,
    MIN(bi.expiration_date) AS earliest_expiry
FROM blood_inventory bi
JOIN donor d ON bi.donor_id = d.donor_id
WHERE bi.status = 'Available'
GROUP BY d.blood_type, d.rh_factor, bi.component_type
ORDER BY available_units ASC;

-- Query 6: Alert on available blood units expiring within the next 7 days, ordered by remaining shelf life.
SELECT 
    bi.unit_id,
    d.blood_type || d.rh_factor AS blood_group,
    bi.component_type,
    bi.collection_date,
    bi.expiration_date,
    (bi.expiration_date - CURRENT_DATE) AS days_left
FROM blood_inventory bi
JOIN donor d ON bi.donor_id = d.donor_id
WHERE bi.status = 'Available'
  AND bi.expiration_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY days_left ASC;

-- Query 7: Calculate monthly dispense workload per staff member for staff with at least 5 dispenses.
SELECT 
    s.staff_id,
    s.first_name || ' ' || s.last_name AS staff_name,
    s.role_title,
    EXTRACT(YEAR FROM dl.dispense_date) AS year,
    EXTRACT(MONTH FROM dl.dispense_date) AS month,
    COUNT(dl.dispense_id) AS total_dispenses
FROM staff s
JOIN dispense_log dl ON s.staff_id = dl.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name, s.role_title, year, month
HAVING COUNT(dl.dispense_id) >= 5
ORDER BY year DESC, month DESC, total_dispenses DESC;

-- Query 8: Rank hospital wards by total blood units requested, including total and 'Stat' request counts.
SELECT 
    w.ward_id,
    w.ward_name,
    COUNT(br.request_id) AS total_requests,
    SUM(br.quantity) AS total_units_requested,
    SUM(CASE WHEN br.urgency_level = 'Stat' THEN 1 ELSE 0 END) AS Stat_requests
FROM wards w
JOIN blood_requests br ON w.ward_id = br.ward_id
GROUP BY w.ward_id, w.ward_name
ORDER BY total_units_requested DESC;

-- Update 1: Automatically mark un-dispensed available blood units past their expiration date as 'Expired'.

-- select the not-available blood units
SELECT unit_id, component_type, expiration_date, status
FROM blood_inventory
WHERE status = 'Available'
  AND expiration_date < CURRENT_DATE
  AND NOT EXISTS (SELECT 1 FROM dispense_log dl WHERE dl.unit_id = blood_inventory.unit_id)
LIMIT 5;

-- update status to expired
UPDATE blood_inventory
SET status = 'Expired'
WHERE status = 'Available'
  AND expiration_date < CURRENT_DATE
  AND NOT EXISTS (
      SELECT 1
      FROM dispense_log dl
      WHERE dl.unit_id = blood_inventory.unit_id
  );

-- Update 2: Synchronize each donor's last_donation_date with their most recent collection_date in blood_inventory.

-- select the donor's last_donation_date
SELECT d.donor_id, d.first_name, d.last_name, d.last_donation_date, sub.max_date
FROM donor d
JOIN (
    SELECT donor_id, MAX(collection_date) AS max_date
    FROM blood_inventory
    GROUP BY donor_id
) sub ON d.donor_id = sub.donor_id
WHERE d.last_donation_date IS NULL OR d.last_donation_date < sub.max_date
LIMIT 5;

-- update 
UPDATE donor d
SET last_donation_date = sub.max_date
FROM (
    SELECT donor_id, MAX(collection_date) AS max_date
    FROM blood_inventory
    GROUP BY donor_id
) sub
WHERE d.donor_id = sub.donor_id
  AND (d.last_donation_date IS NULL OR d.last_donation_date < sub.max_date);

-- Update 3: Escalate pending 'Urgent' blood requests older than 3 days to 'Stat' priority.

-- select all blood requests that older than 3 days.
SELECT request_id, patient_name, urgency_level, requested_date
FROM blood_requests
WHERE urgency_level = 'Urgent'
  AND requested_date < CURRENT_DATE - INTERVAL '3 days'
  AND NOT EXISTS (SELECT 1 FROM dispense_log dl WHERE dl.request_id = blood_requests.request_id)
LIMIT 5;

-- update their priority
UPDATE blood_requests
SET urgency_level = 'Stat'
WHERE urgency_level = 'Urgent'
  AND requested_date < CURRENT_DATE - INTERVAL '3 days'
  AND NOT EXISTS (
      SELECT 1
      FROM dispense_log dl
      WHERE dl.request_id = blood_requests.request_id
  );

-- Delete 1: Remove unfulfilled 'Routine' blood requests that are over one year old.

-- select
SELECT request_id, patient_name, urgency_level, requested_date
FROM blood_requests
WHERE urgency_level = 'Routine'
  AND requested_date < CURRENT_DATE - INTERVAL '1 year'
  AND NOT EXISTS (SELECT 1 FROM dispense_log dl WHERE dl.request_id = blood_requests.request_id);

-- delete
DELETE FROM blood_requests
WHERE urgency_level = 'Routine'
  AND requested_date < CURRENT_DATE - INTERVAL '1 year'
  AND NOT EXISTS (
      SELECT 1
      FROM dispense_log dl
      WHERE dl.request_id = blood_requests.request_id
  );

-- Delete 2: Purge un-dispensed 'Expired' blood units whose expiration date passed more than 6 months ago.

-- select
SELECT COUNT(*) AS expired_to_delete
FROM blood_inventory
WHERE status = 'Expired'
  AND expiration_date < CURRENT_DATE - INTERVAL '6 months'
  AND NOT EXISTS (SELECT 1 FROM dispense_log dl WHERE dl.unit_id = blood_inventory.unit_id);

-- delete
DELETE FROM blood_inventory
WHERE status = 'Expired'
  AND expiration_date < CURRENT_DATE - INTERVAL '6 months'
  AND NOT EXISTS (
      SELECT 1
      FROM dispense_log dl
      WHERE dl.unit_id = blood_inventory.unit_id
  );

-- Delete 3: Remove stale unfulfilled 'Stat' or 'Emergency' requests older than 3 days to keep the urgent queue clean.

-- select
SELECT br.request_id, w.ward_name, br.patient_name, br.urgency_level, br.requested_date
FROM blood_requests br
JOIN wards w ON br.ward_id = w.ward_id
WHERE br.urgency_level IN ('Stat', 'Emergency')
  AND br.requested_date < CURRENT_DATE - INTERVAL '3 days'
  AND NOT EXISTS (
      SELECT 1 FROM dispense_log dl WHERE dl.request_id = br.request_id
  );

-- delete
DELETE FROM blood_requests br
WHERE br.urgency_level IN ('Stat', 'Emergency')
  AND br.requested_date < CURRENT_DATE - INTERVAL '3 days'
  AND NOT EXISTS (
      SELECT 1 FROM dispense_log dl WHERE dl.request_id = br.request_id
  );