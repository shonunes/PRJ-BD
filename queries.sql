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
	INSERT INTO bill(amount) VALUES(50)
	RETURNING id INTO NEW.bill_id;
	
	RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER appointment_bill
BEFORE INSERT ON appointment
FOR EACH ROW
EXECUTE FUNCTION appointment_trig();

CREATE OR REPLACE FUNCTION schedule_appointment(appointment_time TIMESTAMP, doctor_id BIGINT, patient_id BIGINT)
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

	IF (appointment_time < CURRENT_TIMESTAMP) THEN
		RAISE EXCEPTION 'Cannot schedule appointment in the past';
	ELSEIF (appointment_time > CURRENT_TIMESTAMP + INTERVAL '1 month') THEN
		RAISE EXCEPTION 'Cannot schedule appointment more than 1 month in advance';
	ELSEIF (EXISTS (SELECT *
					FROM appointment
					WHERE start_time
					BETWEEN appointment_time - INTERVAL '29 minutes' AND appointment_time + INTERVAL '29 minutes'
					AND doctor_cc = doc_cc)
			) THEN
		RAISE EXCEPTION 'Doctor already has an appointment at this time';
	END IF;

	INSERT INTO appointment(start_time, doctor_cc, patient_cc)
	VALUES(appointment_time, doc_cc, patient_id)
	RETURNING id INTO appointment_id;

	RETURN appointment_id;
END;
$$;