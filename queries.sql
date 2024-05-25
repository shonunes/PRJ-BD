/* ADD_PATIENT
Ter em atenção que os últimos 2 campos podem ser NULL
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE PROCEDURE add_patient(cc_num BIGINT, patient_name VARCHAR, hashcode VARCHAR, health_number BIGINT, sos_contact BIGINT, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO patient
	VALUES (cc_num, patient_name, hashcode, health_number, sos_contact, birthday, email);

	EXCEPTION
		WHEN UNIQUE_VIOLATION THEN
			RAISE EXCEPTION 'Primary key already exists';
		WHEN OTHERS THEN
			RAISE EXCEPTION 'Error adding patient';
END;
$$;

/* ADDING GENERAL EMPLOYEE INFORMATION
Atenção com os campos que podem ser NULL
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION add_emp(cc_num BIGINT, emp_name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
	INSERT INTO employee (cc, name, hashcode, contract_id, salary, contract_issue_date, contract_due_date, birthday, email)
	VALUES (cc_num, emp_name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email)
	RETURNING emp_num INTO user_id;

	RETURN user_id;

	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding employee';
END;
$$;

/* ADD_ASSISTANT
Atenção com os campos que podem ser NULL
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION add_assistant(cc_num BIGINT, name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
	user_id := add_emp(cc_num, name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);
	INSERT INTO assistant
	VALUES(cc_num);

	RETURN user_id;

	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding assistant';
END;
$$;

/* ADD_NURSE
Atenção com os campos que podem ser NULL
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION add_nurse(cc_num BIGINT, name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR, cc_boss BIGINT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
	user_id := add_emp(cc_num, name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);
	INSERT INTO nurse VALUES(cc_num);
	IF (cc_boss IS NOT NULL) THEN
		INSERT INTO nurse_hierarchy
		VALUES(cc_num, cc_boss);
	END IF;

	RETURN user_id;

	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding nurse';
END;
$$;

/* ADDING DOCTOR
Atenção com os campos que podem ser NULL 
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION add_doctor(cc_num BIGINT, name VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR, license_id VARCHAR, license_issue_date DATE, license_due_date DATE, license_comp VARCHAR, specialty_name VARCHAR)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
	user_id := add_emp(cc_num, name, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);
	INSERT INTO doctor
	VALUES(cc_num, license_id, license_comp, license_issue_date, license_due_date);

	IF (NOT specialty_exists(specialty_name)) THEN
		CALL add_specialty(specialty_name, NULL);
	END IF;
	INSERT INTO doctor_specialty
	VALUES(cc_num, specialty_name);

	RETURN user_id;

	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding doctor';
END;
$$;

/* ADDING SPECIALTY 
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE PROCEDURE add_specialty(specialty_name VARCHAR, specialty_parent VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO specialty
	VALUES(specialty_name);
	IF (specialty_parent IS NOT NULL) THEN
		INSERT INTO specialty_hierarchy
		VALUES(specialty_name, specialty_parent);
	END IF;

	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding specialty';
END;
$$;

/* CHECKING IF SPECIALTY EXISTS */
CREATE OR REPLACE FUNCTION specialty_exists(specialty_name VARCHAR) 
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
	res INTEGER;
BEGIN
	SELECT COUNT(*) INTO res 
	FROM specialty
	WHERE name = specialty_name;
	return res = 1;
END;
$$;



/* SCHEDULE APPOINTMENT
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION appointment_trig() RETURNS TRIGGER
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

CREATE OR REPLACE FUNCTION schedule_appointment(appointment_time TIMESTAMP, doctor_id BIGINT, patient_id BIGINT, nurse_id BIGINT[] DEFAULT NULL, nurse_role VARCHAR(128)[] DEFAULT NULL)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	appointment_id INTEGER;
	doc_cc INTEGER;
BEGIN
	SELECT cc INTO doc_cc
	FROM employee
	WHERE emp_num = doctor_id;

	IF (doc_cc IS NULL) THEN
		RAISE EXCEPTION 'Doctor not found';
	END IF;

	IF (appointment_time < CURRENT_TIMESTAMP) THEN
		RAISE EXCEPTION 'Cannot schedule appointment in the past';
	ELSEIF (appointment_time > CURRENT_TIMESTAMP + INTERVAL '3 months') THEN
		RAISE EXCEPTION 'Cannot schedule appointment more than 3 months in advance';
	ELSEIF (EXISTS (SELECT *
					FROM appointment
					WHERE start_time = appointment_time
					AND (doctor_cc = doc_cc OR patient_cc = patient_id))
			) THEN
		RAISE EXCEPTION 'Doctor or patient already has an appointment at this time';
	ELSEIF (EXISTS (SELECT *
					FROM surgery
					WHERE start_time
					BETWEEN appointment_time - INTERVAL '2 hours' + '1 second' AND appointment_time
					AND doctor_cc = doc_cc)
			) THEN
		RAISE EXCEPTION 'Doctor already has a surgery at this time';
	-- TODO: check if the nurses are available
	END IF;

	INSERT INTO appointment(start_time, doctor_cc, patient_cc)
	VALUES(appointment_time, doc_cc, patient_id)
	RETURNING id INTO appointment_id;

	IF (nurse_id IS NOT NULL) THEN
		INSERT INTO appointment_role
		VALUES(UNNEST(nurse_role), appointment_id, UNNEST(nurse_id));
	END IF;

	RETURN appointment_id;
END;
$$;


CREATE OR REPLACE FUNCTION hospitalization_trig() RETURNS TRIGGER
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

CREATE OR REPLACE FUNCTION surgery_trig() RETURNS TRIGGER
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

/* SCHEDULE SURGERY
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION schedule_surgery(patient_id BIGINT, doctor_id BIGINT, nurse_id BIGINT[], nurse_role VARCHAR(128)[], surgery_time TIMESTAMP, hospitalization_id BIGINT, hosp_entry_time TIMESTAMP DEFAULT NULL, hosp_exit_time TIMESTAMP DEFAULT NULL, hosp_nurse BIGINT DEFAULT NULL)
RETURNS TABLE (
    surg_id BIGINT,
    hosp_id BIGINT,
    bill_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
	surgery_id BIGINT;
	doc_cc BIGINT;
	hosp_bill_id INTEGER DEFAULT NULL;
BEGIN
	SELECT cc INTO doc_cc
	FROM employee
	WHERE emp_num = doctor_id;

	IF (surgery_time < CURRENT_TIMESTAMP) THEN
		RAISE EXCEPTION 'Cannot schedule surgery in the past';
	ELSEIF (surgery_time > CURRENT_TIMESTAMP + INTERVAL '6 months') THEN
		RAISE EXCEPTION 'Cannot schedule surgery more than 6 months in advance';
	ELSEIF (EXISTS (SELECT start_time
					FROM surgery AS s, hospitalization AS h
					WHERE start_time
					BETWEEN surgery_time - INTERVAL '2 hours' + INTERVAL '1 second' 
					AND surgery_time + INTERVAL '2 hours' - INTERVAL '1 second'
					AND (doctor_cc = doc_cc OR patient_cc = patient_id))
			) THEN
		RAISE EXCEPTION 'Doctor or patient already has a surgery at this time';
	ELSEIF (EXISTS (SELECT *
					FROM appointment
					WHERE start_time
					BETWEEN surgery_time AND surgery_time + INTERVAL '2 hours' - INTERVAL '1 second'
					AND (doctor_cc = doc_cc OR patient_cc = patient_id))
			) THEN
		RAISE EXCEPTION 'Doctor or patient already has an appointment at this time';
	-- TODO: check if the nurses are available
	END IF;

	IF (hosp_entry_time IS NOT NULL) THEN
		INSERT INTO hospitalization(entry_time, exit_time, nurse_cc, patient_cc)
		VALUES(hosp_entry_time, hosp_exit_time, hosp_nurse, patient_id)
		RETURNING id, bill_id INTO hospitalization_id, hosp_bill_id;
	ELSE
		SELECT h.bill_id INTO hosp_bill_id
		FROM hospitalization AS h
		WHERE h.id = hospitalization_id;
	END IF;

	INSERT INTO surgery(start_time, doctor_cc, hospitalization_id)
	VALUES(surgery_time, doc_cc, hospitalization_id)
	RETURNING id INTO surgery_id;

	IF (nurse_id IS NOT NULL) THEN
		INSERT INTO surgery_role
		VALUES(UNNEST(nurse_role), surgery_id, UNNEST(nurse_id));
	END IF;
	
	RETURN QUERY
	SELECT  surgery_id, hospitalization_id, hosp_bill_id;
END;
$$;

/* EXECUTE PAYMENT
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE FUNCTION execute_payment(id_bill BIGINT, payment_amount INTEGER, payment_method VARCHAR, user_id BIGINT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	bill_patient INTEGER;
	bill_amount INTEGER;
	paid_amount INTEGER;
BEGIN
	IF (payment_amount <= 0) THEN
		RAISE EXCEPTION 'Payment must be positive';
	END IF;

	SELECT patient_cc INTO bill_patient
	FROM appointment
	WHERE bill_id = id_bill;

	IF (bill_patient IS NULL) THEN
		SELECT patient_cc INTO bill_patient
		FROM hospitalization
		WHERE bill_id = id_bill;
	END IF;

	IF (bill_patient IS NULL) THEN
		RAISE EXCEPTION 'Bill not found';
	ELSEIF (bill_patient != user_id) THEN
		RAISE EXCEPTION 'Only the patient can pay the bill';
	END IF;


	SELECT SUM(amount) INTO paid_amount
	FROM payment
	WHERE bill_id = id_bill;
	IF (paid_amount IS NULL) THEN
		paid_amount = 0;
	END IF;

	SELECT amount INTO bill_amount
	FROM bill
	WHERE id = id_bill;

	IF (paid_amount + payment_amount > bill_amount) THEN
		RAISE EXCEPTION 'Payment amount exceeds bill amount';
	ELSEIF (paid_amount + payment_amount = bill_amount) THEN
		UPDATE bill
		SET paid = TRUE
		WHERE id = id_bill;
	END IF;

	INSERT INTO payment(amount, method, bill_id)
	VALUES(payment_amount, payment_method, id_bill);

	RETURN bill_amount - paid_amount - payment_amount;
END;
$$;

-- ADD_PRESCRIPTIONS AND MEDICINE

CREATE OR REPLACE FUNCTION add_prescription(type VARCHAR, val DATE, event_id BIGINT) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	prescription_id INTEGER;
BEGIN
	IF type = 'appointment' THEN
		IF NOT EXISTS (SELECT * FROM appointment WHERE id = event_id) THEN
			RAISE NOTICE 'Invalid appointment';
			RETURN -1;
		ELSE
		INSERT INTO prescription(validity) VALUES (val) RETURNING id INTO prescription_id;
		RETURN prescription_id;
		END IF;
	ELSEIF type = 'hospitalization' THEN
		IF NOT EXISTS (SELECT * FROM hospitalization WHERE id = event_id) THEN
			RAISE NOTICE 'Invalid hospitalization';
			RETURN -1;
		ELSE
			INSERT INTO prescription(validity) VALUES (val) RETURNING id INTO prescription_id;
			RETURN prescription_id;
		END IF;
	ELSE
		RAISE EXCEPTION 'Invalid event';
		RETURN -1;
	END IF;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'Error adding prescription: %', SQLERRM;
	RETURN -1;
END;
$$;


CREATE OR REPLACE PROCEDURE add_medicine(med_name VARCHAR, posology_dose VARCHAR, posology_freq VARCHAR, id_prescription BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
	IF NOT EXISTS (SELECT * FROM prescription WHERE id = id_prescription) THEN
		RAISE EXCEPTION 'Invalid prescription';
	END IF;
	IF NOT EXISTS (SELECT * FROM medicine WHERE name = med_name) THEN
		INSERT INTO medicine(name)
		VALUES(med_name);
	END IF;
	INSERT INTO medicine_dosage(quantity, frequency, medicine_name, prescription_id)
	VALUES(posology_dose, posology_freq, med_name, id_prescription);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'Error adding medicine: %', SQLERRM;
END
$$;



CREATE OR REPLACE PROCEDURE add_side_effect(sideffect_occurrence VARCHAR, description VARCHAR, med_name VARCHAR, sideffect_degree VARCHAR) RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT * FROM side_effect WHERE occurrence = sideffect_occurrence) THEN
        INSERT INTO side_effect
        VALUES(sideffect_occurrence, description);
        INSERT INTO reaction_severity(degree, side_effect_occurrence, medicine_name)
        VALUES(sideffect_degree, sideffect_occurrence, med_name);
        RETURN;
    ELSEIF NOT EXISTS (SELECT * FROM reaction_severity WHERE degree = sideffect_degree AND side_effect_occurrence = sideffect_occurrence AND medicine_name = medicine_name) THEN
        INSERT INTO reaction_severity(degree, side_effect_occurrence, medicine_name)
        VALUES(sideffect_degree, sideffect_occurrence, med_name);
        RETURN;
    ELSE
        RAISE NOTICE 'Side effect already exists at that degree assigned to that medicine';
        RETURN;	
    END IF;
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error adding side effect: %', SQLERRM;
END;
$$;

CREATE TYPE side_effect_type AS (
    occurrence VARCHAR,
    description VARCHAR,
    degree VARCHAR
);

CREATE OR REPLACE FUNCTION add_medicine_with_side_effects(med_name VARCHAR, posology_dose VARCHAR, posology_freq VARCHAR, id_prescription BIGINT, side_effects side_effect_type[])
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    side_effect side_effect_type;
BEGIN
    CALL add_medicine(med_name, posology_dose, posology_freq, id_prescription);
    FOREACH side_effect IN ARRAY side_effects
    LOOP
        CALL add_side_effect(side_effect.occurrence, side_effect.description, med_name, side_effect.degree);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding medicine with side effects: %', SQLERRM;
END;
$$;
