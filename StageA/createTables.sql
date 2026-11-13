CREATE TABLE DONOR (
    donor_id VARCHAR(9) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    blood_type VARCHAR(3) NOT NULL,
    rh_factor VARCHAR(1) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    last_donation_date DATE,
    gender VARCHAR(10) NOT NULL
);

CREATE TABLE BLOOD_INVENTORY (
    unit_id VARCHAR(20) PRIMARY KEY,
    component_type VARCHAR(50) NOT NULL,
    collection_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    volume_ml INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    hemoglobin NUMERIC(4,1),
    weight NUMERIC(5,1),
    blood_pressure VARCHAR(10),
    pulse INT,
    donor_id VARCHAR(9) NOT NULL,
    FOREIGN KEY (donor_id) REFERENCES DONOR(donor_id)
);

CREATE TABLE WARDS (
    ward_id SERIAL PRIMARY KEY,
    ward_name VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL
);

CREATE TABLE STAFF (
    staff_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role_title VARCHAR(50) NOT NULL
);

CREATE TABLE BLOOD_REQUESTS (
    request_id SERIAL PRIMARY KEY,
    requested_blood_type VARCHAR(3) NOT NULL,
    quantity INT NOT NULL,
    urgency_level VARCHAR(20) NOT NULL,
    requested_date DATE NOT NULL,
    requested_rh VARCHAR(1) NOT NULL,
    patient_name VARCHAR(100) NOT NULL,
    patient_mrn VARCHAR(20) NOT NULL,
    ordering_physician VARCHAR(100) NOT NULL,
    ward_id INT NOT NULL,
    FOREIGN KEY (ward_id) REFERENCES WARDS(ward_id)
);

CREATE TABLE DISPENSE_LOG (
    dispense_id SERIAL PRIMARY KEY,
    dispense_date DATE NOT NULL,
    request_id INT NOT NULL,
    unit_id VARCHAR(20) NOT NULL,
    staff_id VARCHAR(20) NOT NULL,
    FOREIGN KEY (request_id) REFERENCES BLOOD_REQUESTS(request_id),
    FOREIGN KEY (unit_id) REFERENCES BLOOD_INVENTORY(unit_id),
    FOREIGN KEY (staff_id) REFERENCES STAFF(staff_id)
);