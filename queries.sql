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
Simplificado - adicionar enfermeiras com determinadas funções
POR TESTAR
*/
CREATE OR REPLACE FUNCTION appointment_trig() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	overlap_appointments INTEGER;
BEGIN
	--- tornar o bill_id auto increment (AU) e ver como funciona ---
	INSERT INTO bill(amount) VALUES(new.cost, nextval('bill_id_seq'));
	--- quando existir um pagamento, diminuir o valor da despesa ---
	RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER appointment_bill
BEFORE INSERT ON appointment
FOR EACH ROW
EXECUTE FUNCTION appointment_trig();

--- TODO: verificar se já há consulta nesta hora ---CREATE OR REPLACE PROCEDURE 
CREATE OR REPLACE PROCEDURE add_appointment(
    ap_start_time TIMESTAMP,
    ap_end_time TIMESTAMP,
    ap_cost INTEGER,
    doc_cc BIGINT,
    pat_cc BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE 
    overlap_appointments INT;
BEGIN
    -- Check for overlapping appointments for the doctor
    SELECT COUNT(*) INTO overlap_appointments
    FROM appointment
    WHERE doctor_cc = doc_cc
    AND (
        (start_time <= ap_start_time AND end_time > ap_start_time)
        OR (start_time < ap_end_time AND end_time >= ap_end_time)
        OR (start_time >= ap_start_time AND end_time <= ap_end_time)
    );
    
    -- Raise an exception if there are overlapping appointments
    IF overlap_appointments > 0 THEN
        RAISE EXCEPTION 'Doctor is not available at the requested time';
    END IF;
    
    -- Insert the new appointment
    INSERT INTO appointment (start_time, end_time, cost, doctor_cc, patient_cc) 
    VALUES (ap_start_time, ap_end_time, ap_cost, doc_cc, pat_cc);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding appointment: %', SQLERRM;
END;
$$;



/* SEE PATIENT APPOINTMENTS
Ver se é necessário retornar mais coisas (p.e. nome do doutor)
E possivelmente mudar o start_time para o tipo data
*/ 
SELECT a.id, a.doctor_license_employee_contract_person_cc, a.start_time
FROM appointment AS a
WHERE a.patient_person_cc = cc_num;


CREATE OR REPLACE PROCEDURE add_surgery(ap_start_time TIMESTAMP, ap_duration TIMESTAMP, ap_cost INTEGER, doctor_cc BIGINT, patient_cc BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE 
	overlap_surgeries INT;
BEGIN
    SELECT COUNT(*) INTO overlap_appointments
    FROM appointment as app
    WHERE app.doctor_cc = doctor_cc
    AND (
        (start_time <= app.ap_start_time AND start_time + duration > app.ap_start_time)
        OR (start_time < ap_start_time + ap_duration AND start_time + duration >= app.ap_start_time + ap_duration)
        OR (start_time >= ap_start_time AND start_time + duration <= ap_start_time + ap_duration)
    );
    IF overlap_appointments > 0 THEN
        RAISE EXCEPTION 'Doctor is not available at the requested time';
    END IF;
	--- Mais 1x verificar como funciona o AU --
	INSERT INTO appointment(start_time, end_time, cost, doctor_cc, patient_cc) 
	VALUES(ap_start_time, end_time, ap_cost, doctor_cc, patient_cc);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding appointment';
END;
$$;


