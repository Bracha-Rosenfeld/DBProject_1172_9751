import random
from datetime import datetime, timedelta

# הגדרת כמויות רשומות לפי דרישות הפרויקט
NUM_DONORS = 600
NUM_WARDS = 500
NUM_STAFF = 500
NUM_REQUESTS = 600
NUM_INVENTORY = 20000
NUM_DISPENSE = 20000

OUTPUT_FILE = "insertTables.sql"

# מאגרי נתונים בסיסיים ליצירת רשומות מגוונות
FIRST_NAMES = ["Yosef", "David", "Moshe", "Avraham", "Yitzhak", "Yaakov", "Shlomo", "Daniel", "Ariel", "Noam",
               "Sarah", "Rivka", "Rachel", "Leah", "Miriam", "Esther", "Tamar", "Yael", "Michal", "Noa"]
LAST_NAMES = ["Cohen", "Levi", "Mizrahi", "Peretz", "Biton", "Dahan", "Avraham", "Friedman", "Malka", "Azoulay",
              "Katz", "Yosef", "Amar", "Ohayon", "Hadad", "Gabay", "Ben-David", "Shapira", "Klein", "Goldstein"]
BLOOD_TYPES = ["A", "B", "AB", "O"]
RH_FACTORS = ["+", "-"]
GENDERS = ["Male", "Female"]
COMPONENTS = ["Whole Blood", "Red Blood Cells", "Platelets", "Plasma", "Cryoprecipitate"]
STATUSES = ["Available", "Reserved", "Dispensed", "Expired"]
URGENCIES = ["Routine", "Urgent", "Emergency", "Stat"]
ROLES = ["Lab Technician", "Hematologist", "Blood Bank Nurse", "Shift Supervisor", "Medical Technologist"]
WARD_PREFIXES = ["Internal Medicine", "Surgery", "Pediatrics", "Emergency", "Cardiology", "Oncology", "Orthopedics", "ICU", "Neurology", "Maternity"]

def random_date(start_year=1960, end_year=2005):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    return start + timedelta(days=random.randint(0, (end - start).days))

def format_date(dt):
    return dt.strftime("%Y-%m-%d")

def write_batched_inserts(f, table_name, columns, rows, batch_size=1000):
    cols_str = ", ".join(columns)
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        values_str = ",\n".join(batch)
        f.write(f"INSERT INTO {table_name} ({cols_str}) VALUES\n{values_str};\n\n")

def main():
    print("Generating data...")
    
    # 1. יצירת DONOR (600 רשומות)
    donor_ids = [f"{100000000 + i}" for i in range(1, NUM_DONORS + 1)]
    donor_rows = []
    for d_id in donor_ids:
        fn = random.choice(FIRST_NAMES)
        ln = random.choice(LAST_NAMES)
        dob = format_date(random_date(1960, 2005))
        bt = random.choice(BLOOD_TYPES)
        rh = random.choice(RH_FACTORS)
        phone = f"05{random.randint(0, 8)}-{random.randint(1000000, 9999999)}"
        last_don = format_date(random_date(2023, 2026))
        gender = random.choice(GENDERS)
        donor_rows.append(f"('{d_id}', '{fn}', '{ln}', '{dob}', '{bt}', '{rh}', '{phone}', '{last_don}', '{gender}')")

    # 2. יצירת WARDS (500 רשומות - מזהה SERIAL מ-1 עד 500)
    ward_rows = []
    for i in range(1, NUM_WARDS + 1):
        w_name = f"{random.choice(WARD_PREFIXES)} Unit {i}"
        phone = f"02-{random.randint(5000000, 6999999)}"
        ward_rows.append(f"('{w_name}', '{phone}')")

    # 3. יצירת STAFF (500 רשומות)
    staff_ids = [f"STF-{1000 + i}" for i in range(1, NUM_STAFF + 1)]
    staff_rows = []
    for s_id in staff_ids:
        fn = random.choice(FIRST_NAMES)
        ln = random.choice(LAST_NAMES)
        role = random.choice(ROLES)
        staff_rows.append(f"('{s_id}', '{fn}', '{ln}', '{role}')")

    # 4. יצירת BLOOD_REQUESTS (600 רשומות - מזהה SERIAL מ-1 עד 600)
    request_rows = []
    for i in range(1, NUM_REQUESTS + 1):
        bt = random.choice(BLOOD_TYPES)
        qty = random.randint(1, 6)
        urg = random.choice(URGENCIES)
        req_date = format_date(random_date(2025, 2026))
        rh = random.choice(RH_FACTORS)
        p_name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        p_mrn = f"MRN-{100000 + i}"
        doc = f"Dr. {random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        ward_id = random.randint(1, NUM_WARDS)
        request_rows.append(f"('{bt}', {qty}, '{urg}', '{req_date}', '{rh}', '{p_name}', '{p_mrn}', '{doc}', {ward_id})")

    # 5. יצירת BLOOD_INVENTORY (20,000 רשומות)
    unit_ids = [f"UNIT-{100000 + i}" for i in range(1, NUM_INVENTORY + 1)]
    inventory_rows = []
    for u_id in unit_ids:
        comp = random.choice(COMPONENTS)
        coll_dt = random_date(2025, 2026)
        exp_dt = coll_dt + timedelta(days=random.randint(5, 42))
        vol = random.choice([250, 300, 450, 500])
        status = random.choice(STATUSES)
        hb = round(random.uniform(12.0, 17.5), 1)
        wt = round(random.uniform(50.0, 110.0), 1)
        bp = f"{random.randint(105, 135)}/{random.randint(65, 85)}"
        pulse = random.randint(60, 95)
        d_id = random.choice(donor_ids)
        inventory_rows.append(
            f"('{u_id}', '{comp}', '{format_date(coll_dt)}', '{format_date(exp_dt)}', {vol}, '{status}', {hb}, {wt}, '{bp}', {pulse}, '{d_id}')"
        )

    # 6. יצירת DISPENSE_LOG (20,000 רשומות)
    dispense_rows = []
    for i in range(NUM_DISPENSE):
        disp_date = format_date(random_date(2025, 2026))
        req_id = random.randint(1, NUM_REQUESTS)
        u_id = unit_ids[i]  # התאמה ייחודית למנת דם
        s_id = random.choice(staff_ids)
        dispense_rows.append(f"('{disp_date}', {req_id}, '{u_id}', '{s_id}')")

    # כתיבת כל הפקודות לקובץ SQL
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("-- Auto-generated SQL insert script for Hospital Blood Bank\n\n")
        
        write_batched_inserts(f, "DONOR", 
            ["donor_id", "first_name", "last_name", "date_of_birth", "blood_type", "rh_factor", "phone", "last_donation_date", "gender"], 
            donor_rows)
        
        write_batched_inserts(f, "WARDS", 
            ["ward_name", "contact_phone"], 
            ward_rows)
        
        write_batched_inserts(f, "STAFF", 
            ["staff_id", "first_name", "last_name", "role_title"], 
            staff_rows)
        
        write_batched_inserts(f, "BLOOD_REQUESTS", 
            ["requested_blood_type", "quantity", "urgency_level", "requested_date", "requested_rh", "patient_name", "patient_mrn", "ordering_physician", "ward_id"], 
            request_rows)
        
        write_batched_inserts(f, "BLOOD_INVENTORY", 
            ["unit_id", "component_type", "collection_date", "expiration_date", "volume_ml", "status", "hemoglobin", "weight", "blood_pressure", "pulse", "donor_id"], 
            inventory_rows)
        
        write_batched_inserts(f, "DISPENSE_LOG", 
            ["dispense_date", "request_id", "unit_id", "staff_id"], 
            dispense_rows)

    print(f"Done! Created {OUTPUT_FILE} successfully.")

if __name__ == "__main__":
    main()