/* FUNCTIONS */
CREATE OR REPLACE FUNCTION specialty_exists(specialty VARCHAR) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE 
	res INTEGER;
BEGIN
	SELECT COUNT(*) INTO res 
	FROM especiality
	WHERE name = specialty;
	return res = 1;
END;
$$;


/* Procedures */

/* ADDING PATIENT
Ter em atenção que os últimos 2 campos podem ser NULL
TESTADO E FUNCIONAL NO ENDPOINT
*/
CREATE OR REPLACE PROCEDURE add_patient(cc_num BIGINT, username VARCHAR, hashcode VARCHAR, health_number BIGINT, sos_contact BIGINT, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO patient
	VALUES (cc_num, username, hashcode, health_number, sos_contact, birthday, email);
	
	EXCEPTION
		WHEN UNIQUE_VIOLATION THEN
			RAISE EXCEPTION 'Primary key already exists';
		WHEN OTHERS THEN
			RAISE EXCEPTION 'Error adding patient';
END;
$$;

/* ADDING GENERAL EMPLOYEE INFORMATION */
CREATE OR REPLACE PROCEDURE add_emp(cc_num BIGINT, username VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO employee (cc, username, hashcode, contract_id, salary, contract_issue_date, contract_due_date, birthday, email)
	VALUES (cc_num, username, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);
	
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding employee';
END;
$$;

CREATE OR REPLACE PROCEDURE add_assistant(cc_num BIGINT, username VARCHAR, hashcode VARCHAR, contract_id BIGINT, sal INT, contract_issue_date DATE, contract_due_date DATE, birthday DATE, email VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(cc_num, username, hashcode, contract_id, sal, contract_issue_date, contract_due_date, birthday, email);
	INSERT INTO assistant VALUES(cc_num);
	
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding assistant';
END;
$$;

/*ADDING NURSE LICENSE*/
CREATE OR REPLACE PROCEDURE add_nurse(empnum BIGINT, id_contract BIGINT, sal INT, cont_day DATE, due_date DATE, cc BIGINT, p_name VARCHAR, bday DATE)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(empnum, id_contract, sal, cont_day, due_date, cc, p_name, bday);
	INSERT INTO nurse VALUES(id_contract);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding nurse';
END;
$$;

/*ADDING DOCTOR LICENSE*/
CREATE OR REPLACE PROCEDURE add_doctor(empnum BIGINT, id_contract BIGINT, sal INT, cont_day DATE, contract_due_date DATE, cc BIGINT, p_name VARCHAR, bday DATE, id_license VARCHAR, license_comp VARCHAR, issue_date DATE, l_due_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(empnum, id_contract, sal, cont_day, contract_due_date, cc, p_name, bday);
	INSERT INTO doctor_license(license_id, license_company_name, license_issue_date, license_due_date, employee_contract_person_cc) VALUES(id_license, license_comp, issue_date, l_due_date, cc);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding doctor';
END;
$$;

CREATE OR REPLACE PROCEDURE add_doctor(empnum BIGINT, id_contract BIGINT, sal INT, cont_day DATE, contract_due_date DATE, cc BIGINT, p_name VARCHAR, bday DATE, id_license VARCHAR, license_comp VARCHAR, issue_date DATE, l_due_date DATE, specialty VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	CALL add_emp(empnum, id_contract, sal, cont_day, contract_due_date, cc, p_name, bday);
	INSERT INTO doctor_license(license_id, license_company_name, license_issue_date, license_due_date, employee_contract_person_cc) VALUES(id_license, license_comp, issue_date, l_due_date, cc);
	IF (NOT specialty_exists(specialty)) THEN
		CALL add_specialty(specialty);
	END IF;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding doctor';
END;
$$;

call add_doctor(1, 1, 0, 0100-01-01, 0100-01-02, 0,varchar 'Daniela', 1-1-1,varchar 'ola',varchar 'OLA', 0001-01-01,  0001-01-03,varchar 'EXISTIR');


/*ADDING HIERARCHY BETWEEN NURSES*/
CREATE OR REPLACE PROCEDURE add_nurse_hierarchy(superior_cc BIGINT, inferior_cc BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO nurse_nurse(nurse_employee_contract_person_cc, nurse_employee_contract_person_cc1) VALUES(inferior_cc, superior_cc);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding hierarchy between nurses';
END;
$$;

/*ADDING SPECIALTY*/
CREATE OR REPLACE PROCEDURE add_specialty(spec VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO especiality VALUES(spec);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding specialty';
END;
$$;



/* SCHEDULE APPOINTMENT
Simplificado - adicionar enfermeiras com determinadas funções
POR TESTAR
*/
CREATE OR REPLACE FUNCTION appointment_trig() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	--- tornar o bill_id auto increment (AU) e ver como funciona ---
	INSERT INTO bill VALUES(new.bill_id, new.cost);
	--- quando existir um pagamento, diminuir o valor da despesa ---
	RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER appointment_bill
BEFORE INSERT ON appointment
FOR EACH ROW
EXECUTE FUNCTION appointment_trig();

--- TODO: verificar se já há consulta nesta hora ---
CREATE OR REPLACE PROCEDURE add_appointment(ap_start_time TIMESTAMP, ap_duration TIMESTAMP, ap_cost INTEGER, doctor_cc BIGINT, patient_cc BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
	--- Mais 1x verificar como funciona o AU --
	INSERT INTO appointment(start_time, duration, cost, doctor_license_employee_contract_person_cc, patient_person_cc) 
	VALUES(ap_start_time, ap_duration, ap_cost, doctor_cc, patient_cc);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION 'error adding appointment';
END;
$$;



/* SEE PATIENT APPOINTMENTS
Ver se é necessário retornar mais coisas (p.e. nome do doutor)
E possivelmente mudar o start_time para o tipo data
*/ 
SELECT a.id, a.doctor_license_employee_contract_person_cc, a.start_time
FROM appointment AS a
WHERE a.patient_person_cc = cc_num;

