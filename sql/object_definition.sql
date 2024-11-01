/* ADD PATIENT */
CREATE OR REPLACE PROCEDURE add_patient(cc_num BIGINT, patient_name VARCHAR, hashcode VARCHAR, health_number BIGINT, sos_contact BIGINT, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO patient
	VALUES (cc_num, health_number, patient_name, hashcode, sos_contact, birthday, email);

	EXCEPTION
		WHEN UNIQUE_VIOLATION THEN
			RAISE EXCEPTION 'CC or health number already exists in the database';
END;
$$;

/* ADD GENERAL EMPLOYEE INFORMATION */
CREATE OR REPLACE PROCEDURE add_emp(cc_num BIGINT, emp_name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO employee (cc, name, hashcode, contract_id, salary, contract_issue_date, contract_due_date, birthday, email)
	VALUES (cc_num, emp_name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);

	EXCEPTION
		WHEN UNIQUE_VIOLATION THEN
			RAISE EXCEPTION 'CC, email or contract id already exists in the database';
END;
$$;

/* ADD ASSISTANT */
CREATE OR REPLACE PROCEDURE add_assistant(cc_num BIGINT, name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(cc_num, name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);

	INSERT INTO assistant
	VALUES(email);
END;
$$;

/* ADD NURSE */
CREATE OR REPLACE PROCEDURE add_nurse(cc_num BIGINT, name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR, email_superior VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(cc_num, name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);
	
	INSERT INTO nurse VALUES(email);
	IF (email_superior IS NOT NULL) THEN
		INSERT INTO nurse_hierarchy
		VALUES(email, email_superior);
	END IF;
END;
$$;

/* ADD DOCTOR */
CREATE OR REPLACE PROCEDURE add_doctor(
	cc_num BIGINT, 
	doctor_name VARCHAR, 
	hashcode VARCHAR, 
	contract_id BIGINT, 
	sal INT, 
	contract_issue_date DATE, 
	contract_due_date DATE, 
	birthday DATE, 
	email VARCHAR, 
	license_id VARCHAR, 
	license_issue_date DATE, 
	license_due_date DATE, 
	license_comp VARCHAR, 
	specialty_names VARCHAR[],
	specialty_parents VARCHAR[]
)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(cc_num, doctor_name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);

	INSERT INTO doctor
	VALUES(email, license_id, license_comp, license_issue_date, license_due_date);

	INSERT INTO specialty(name)
    SELECT unnest(specialty_names)
    ON CONFLICT (name) DO NOTHING;

	INSERT INTO specialty(name)
    SELECT unnest(specialty_parents)
    ON CONFLICT (name) DO NOTHING;

    INSERT INTO specialty_hierarchy(specialty_name, specialty_parent)
    SELECT s_name, s_parent
    FROM unnest(specialty_names) AS s_name
    LEFT JOIN unnest(specialty_parents) AS s_parent ON true
    WHERE s_parent IS NOT NULL;

    INSERT INTO doctor_specialty(doctor_email, specialty_name)
    SELECT email, unnest(specialty_names);
END;
$$;

/* LOGIN EMPLOYEE */
CREATE OR REPLACE FUNCTION login_employee(emp_email VARCHAR)
RETURNS TABLE
(
	type VARCHAR(128),
	hashcode VARCHAR(128)
)
LANGUAGE plpgsql
AS $$
DECLARE
	assistant_email VARCHAR(128);
	nurse_email VARCHAR(128);
	doctor_email VARCHAR(128);
BEGIN
	SELECT e.hashcode, a.email, n.email, d.email 
	INTO hashcode, assistant_email, nurse_email, doctor_email
	FROM employee AS e
	LEFT JOIN assistant AS a ON e.email = a.email
	LEFT JOIN nurse AS n ON e.email = n.email
	LEFT JOIN doctor AS d ON e.email = d.email
	WHERE e.email = emp_email;

	IF (assistant_email IS NOT NULL) THEN
		type := 'assistant';
	ELSIF (nurse_email IS NOT NULL) THEN
		type := 'nurse';
	ELSIF (doctor_email IS NOT NULL) THEN
		type := 'doctor';
	ELSE
		RAISE EXCEPTION 'Employee not found';
	END IF;

	RETURN QUERY
	SELECT type, hashcode;
END;
$$;


/* SCHEDULE APPOINTMENT */
CREATE OR REPLACE FUNCTION appointment_trig() 
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO bill(amount, paid) VALUES(50, false)
	RETURNING id INTO NEW.bill_id;

	RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER appointment_bill
BEFORE INSERT ON appointment
FOR EACH ROW
EXECUTE FUNCTION appointment_trig();

CREATE OR REPLACE FUNCTION schedule_appointment(appointment_time TIMESTAMP, doctor_id VARCHAR(128), patient_id BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
	appointment_id BIGINT;
BEGIN
	IF (appointment_time < CURRENT_TIMESTAMP) THEN
		RAISE EXCEPTION 'Cannot schedule appointment in the past';
	ELSIF (appointment_time > CURRENT_TIMESTAMP + INTERVAL '3 months') THEN
		RAISE EXCEPTION 'Cannot schedule appointment more than 3 months in advance';
	END IF;

	IF EXISTS (
			SELECT 1
			FROM appointment AS a
			FULL OUTER JOIN surgery AS s ON TRUE
			FULL OUTER JOIN hospitalization AS h ON s.hospitalization_id = h.id
			WHERE
				-- Check appointment overlaps
				a.start_time = appointment_time
				AND (a.doctor_email = doctor_id OR a.patient_cc = patient_id)
			OR
				-- Check surgery overlaps
				tsrange(appointment_time, appointment_time + INTERVAL '30 minutes')
				&& tsrange(s.start_time, s.end_time)
				AND (s.doctor_email = doctor_id OR h.patient_cc = patient_id)
			OR
				-- Check hospitalization overlaps
				tsrange(appointment_time, appointment_time + INTERVAL '30 minutes')
				&& tsrange(h.entry_time, h.exit_time)
				AND h.patient_cc = patient_id
		) THEN
		RAISE EXCEPTION 'Doctor or patient unavailable at this time';
	END IF;

	INSERT INTO appointment(start_time, doctor_email, patient_cc)
	VALUES(appointment_time, doctor_id, patient_id)
	RETURNING id INTO appointment_id;

	RETURN appointment_id;

	EXCEPTION
		WHEN FOREIGN_KEY_VIOLATION THEN
			RAISE EXCEPTION 'Doctor not found';
END;
$$;


/* SCHEDULE SURGERY */
CREATE OR REPLACE FUNCTION hospitalization_trig() 
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO bill(amount, paid) VALUES(0, false)
	RETURNING id INTO NEW.bill_id;

	RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER hosp_creation_bill
BEFORE INSERT ON hospitalization
FOR EACH ROW
EXECUTE FUNCTION hospitalization_trig();

CREATE OR REPLACE FUNCTION surgery_trig() 
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE 
	hosp_bill_id INTEGER;
BEGIN
	SELECT bill_id INTO hosp_bill_id
	FROM hospitalization
	WHERE id = NEW.hospitalization_id;

	UPDATE bill
	SET amount = amount + 2000
	WHERE id = hosp_bill_id;

	RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER surgery_creation_bill
BEFORE INSERT ON surgery
FOR EACH ROW
EXECUTE FUNCTION surgery_trig();

CREATE OR REPLACE FUNCTION schedule_surgery(patient_id BIGINT, doctor_id VARCHAR(128), nurse_id VARCHAR(128)[], nurse_role VARCHAR(128)[], surgery_start TIMESTAMP, surgery_end TIMESTAMP, hospitalization_id BIGINT, hosp_entry_time TIMESTAMP DEFAULT NULL, hosp_exit_time TIMESTAMP DEFAULT NULL, hosp_nurse VARCHAR(128) DEFAULT NULL)
RETURNS TABLE (
    surg_id BIGINT,
    hosp_id BIGINT,
    bill_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
	surgery_id BIGINT;
	hosp_bill_id BIGINT DEFAULT NULL;
BEGIN
	IF (surgery_start > CURRENT_TIMESTAMP + INTERVAL '6 months') THEN
		RAISE EXCEPTION 'Cannot schedule surgery more than 6 months in advance';
	ELSIF (surgery_start >= surgery_end) THEN
		RAISE EXCEPTION 'Surgery start time must be before end time';
	END IF;

	IF EXISTS (
			SELECT 1
			FROM appointment AS a
			FULL OUTER JOIN appointment_role AS ar ON a.id = ar.appointment_id
			FULL OUTER JOIN surgery AS s ON TRUE
			FULL OUTER JOIN surgery_role AS sr ON s.id = sr.surgery_id
			FULL OUTER JOIN hospitalization AS h ON s.hospitalization_id = h.id
			WHERE
				-- Check appointment overlaps
				tsrange(a.start_time, a.start_time + INTERVAL '30 minutes')
				&& tsrange(surgery_start, surgery_end)
				AND (a.doctor_email = doctor_id OR a.patient_cc = patient_id OR ar.nurse_email = ANY(nurse_id))
			OR
				-- Check hospitalization overlaps
				tsrange(h.entry_time, h.exit_time)
				&& tsrange(surgery_start, surgery_end)
				AND h.patient_cc = patient_id
			OR
				-- Check surgery overlaps
				tsrange(s.start_time, s.end_time)
				&& tsrange(surgery_start, surgery_end)
				AND (s.doctor_email = doctor_id OR h.patient_cc = patient_id OR sr.nurse_email = ANY(nurse_id))
		) THEN
		RAISE EXCEPTION 'Doctor, nurse or patient unavailable at this time';
	END IF;

	IF (hosp_entry_time IS NOT NULL) THEN
		IF (hosp_entry_time >= hosp_exit_time) THEN
			RAISE EXCEPTION 'Hospitalization entry time must be before exit time';
		END IF;
		INSERT INTO hospitalization(entry_time, exit_time, nurse_email, patient_cc)
		VALUES(hosp_entry_time, hosp_exit_time, hosp_nurse, patient_id)
		RETURNING id, hospitalization.bill_id INTO hospitalization_id, hosp_bill_id;
	ELSE
		SELECT h.bill_id INTO hosp_bill_id
		FROM hospitalization AS h
		WHERE h.id = hospitalization_id;
	END IF;

	INSERT INTO surgery(start_time, end_time, doctor_email, hospitalization_id)
	VALUES(surgery_start, surgery_end, doctor_id, hospitalization_id)
	RETURNING id INTO surgery_id;

	IF (nurse_id IS NOT NULL) THEN
		INSERT INTO surgery_role
		VALUES(UNNEST(nurse_role), surgery_id, UNNEST(nurse_id));
	END IF;

	RETURN QUERY
	SELECT surgery_id, hospitalization_id, hosp_bill_id;
END;
$$;


/* EXECUTE PAYMENT */
CREATE OR REPLACE FUNCTION execute_payment(id_bill BIGINT, payment_amount INTEGER, payment_method VARCHAR, user_id BIGINT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	appt_cc BIGINT;
	hosp_cc BIGINT;
	bill_amount INTEGER;
	paid_amount INTEGER;
	bill_paid BOOLEAN;
	bill_patient BIGINT;
BEGIN
	IF (payment_amount <= 0) THEN
		RAISE EXCEPTION 'Payment must be positive';
	END IF;

	SELECT
		sum,
		b.amount,
		paid,
		appt.patient_cc,
		hosp.patient_cc
	INTO 
		paid_amount,
		bill_amount,
		bill_paid,
		appt_cc,
		hosp_cc
	FROM payment_sum AS ps
	LEFT JOIN bill AS b ON b.id = ps.id
	LEFT JOIN appointment AS appt ON appt.bill_id = ps.id
	LEFT JOIN hospitalization AS hosp ON hosp.bill_id = ps.id
	WHERE ps.id = id_bill;

	IF (appt_cc IS NOT NULL) THEN
        bill_patient := appt_cc;
    ELSIF (hosp_cc IS NOT NULL) THEN
        bill_patient := hosp_cc;
    ELSE
        RAISE EXCEPTION 'Bill not found';
    END IF;

	IF (bill_patient != user_id) THEN
		RAISE EXCEPTION 'Only the patient can pay the bill';
	ELSIF (bill_paid) THEN
		RAISE EXCEPTION 'Bill already paid';
	ELSIF (paid_amount + payment_amount > bill_amount) THEN
		RAISE EXCEPTION 'Payment amount exceeds bill amount';
	ELSIF (paid_amount + payment_amount = bill_amount) THEN
		UPDATE bill
		SET paid = TRUE
		WHERE id = id_bill;
	END IF;

	INSERT INTO payment(amount, method, bill_id, date_time)
	VALUES(payment_amount, payment_method, id_bill, CURRENT_TIMESTAMP);

	RETURN bill_amount - paid_amount - payment_amount;
END;
$$;


/* ADD PRESCRIPTIONS AND MEDICINE */
CREATE TYPE medicine_type AS (
    name VARCHAR,
    dose VARCHAR,
    freq VARCHAR
);

CREATE OR REPLACE FUNCTION add_prescription(type VARCHAR, val DATE, event_id BIGINT, medicines medicine_type[])
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
	presc_id BIGINT;
BEGIN
	SELECT add_prescription(type, val, event_id) INTO presc_id;

	-- Insert medicines if they don't exist (when they exist, do nothing)
	INSERT INTO medicine(name)
	SELECT m.name
	FROM UNNEST(medicines) AS m
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO medicine_dosage(quantity, frequency, medicine_name, prescription_id)
	SELECT m.dose, m.freq, m.name, presc_id
	FROM UNNEST(medicines) AS m
	ON CONFLICT (medicine_name, prescription_id) DO NOTHING;

	RETURN presc_id;
END;
$$;

CREATE OR REPLACE FUNCTION add_prescription(type VARCHAR, val DATE, event_id BIGINT) 
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
	prescription_id BIGINT;
BEGIN
	IF type = 'appointment' THEN
		INSERT INTO prescription(validity)
		VALUES (val)
		RETURNING id INTO prescription_id;

		INSERT INTO appointment_prescription
		VALUES(prescription_id, event_id);
	ELSIF type = 'hospitalization' THEN
		INSERT INTO prescription(validity)
		VALUES (val)
		RETURNING id INTO prescription_id;

		INSERT INTO hospitalization_prescription
		VALUES(prescription_id, event_id);
	ELSE
		RAISE EXCEPTION 'Invalid event';
	END IF;

	RETURN prescription_id;

	EXCEPTION
		WHEN FOREIGN_KEY_VIOLATION THEN
			RAISE EXCEPTION 'Event not found';
		WHEN OTHERS THEN
			RAISE EXCEPTION 'Error adding prescription: %', SQLERRM;
END;
$$;

/* VIEWS */
CREATE OR REPLACE VIEW appt_prescriptions AS
SELECT ap.prescription_id AS id, a.patient_cc
FROM appointment_prescription AS ap
JOIN appointment AS a ON a.id = ap.appointment_id;

CREATE OR REPLACE VIEW hosp_prescriptions AS
SELECT hp.prescription_id AS id, h.patient_cc
FROM hospitalization_prescription AS hp
JOIN hospitalization AS h ON h.id = hp.hospitalization_id;


CREATE OR REPLACE VIEW monthly_payments AS
SELECT
	p.cc AS patient_id,
	SUM(pay.amount) AS total_amount
FROM payment pay
LEFT JOIN appointment a ON a.bill_id = pay.bill_id
LEFT JOIN hospitalization h ON h.bill_id = pay.bill_id
LEFT JOIN patient p ON p.cc = a.patient_cc OR p.cc = h.patient_cc
WHERE
	EXTRACT(YEAR FROM pay.date_time) = EXTRACT(YEAR FROM CURRENT_DATE)
	AND EXTRACT(MONTH FROM pay.date_time) = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY p.cc;

CREATE OR REPLACE VIEW top_patients AS
SELECT patient_id, total_amount
FROM monthly_payments
ORDER BY total_amount DESC;


CREATE OR REPLACE VIEW hospitalization_counts AS
SELECT h.id, COUNT(DISTINCT s.id) AS surgery_count, COUNT(DISTINCT hp.prescription_id) AS prescription_count
FROM hospitalization AS h
LEFT JOIN surgery AS s ON h.id = s.hospitalization_id
LEFT JOIN hospitalization_prescription AS hp ON h.id = hp.hospitalization_id
GROUP BY h.id;

CREATE OR REPLACE VIEW hospitalization_money_spent AS
SELECT h.id, COALESCE(SUM(p.amount), 0) AS total_amount_spent
FROM hospitalization AS h
LEFT JOIN payment AS p ON h.bill_id = p.bill_id
GROUP BY h.id;


CREATE OR REPLACE VIEW doctor_monthly_surgeries AS
SELECT
	doctor_email,
	TO_CHAR(DATE_TRUNC('month', start_time), 'YYYY-MM') AS surgery_month,
	COUNT(id) AS surgery_count
FROM surgery
WHERE start_time >= (CURRENT_DATE - INTERVAL '1 year') AND start_time < CURRENT_DATE
GROUP BY doctor_email, DATE_TRUNC('month', start_time);

CREATE OR REPLACE VIEW max_monthly_surgery_count AS
SELECT
	surgery_month,
	MAX(surgery_count) AS max_surgery_count
FROM doctor_monthly_surgeries
GROUP BY surgery_month;

CREATE OR REPLACE VIEW payment_sum AS
SELECT COALESCE(SUM(p.amount), 0) AS sum, b.id
FROM bill AS b
LEFT JOIN payment AS p ON p.bill_id = b.id
GROUP BY b.id;
