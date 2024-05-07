CREATE OR REPLACE PROCEDURE see_appointments(cc_num BIGINT)
LANGUAGE PLPGSQL
AS $$
BEGIN
    SELECT a.id, a.doctor_license_employee_contract_person_cc, a.start_time
    FROM appointment AS a
    WHERE a.patient_person_cc = cc_num;
END;
$$;


/* FUNCTIONS */
CREATE OR REPLACE FUNCTION specialty_exist(specialty VARCHAR) RETURNS BOOL
LANGUAGE PLPGSQL
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

/*ADDING PATIENT*/
CREATE OR REPLACE PROCEDURE add_patient(h_num Bigint, em_contract varchar, cc Bigint, p_name varchar, p_birthday date)
LANGUAGE PLPGSQL 
AS $$
BEGIN
INSERT INTO patient (health_num, emergency_contact, person_cc, person_name, person_birthday) 
VALUES (h_num, em_contract, cc, p_name, p_birthday);
EXCEPTION
WHEN OTHERS THEN
    RAISE EXCEPTION 'Error adding patient';
END;
$$;

/*ADDING EMPLOYEE CONTRACT*/

CREATE OR REPLACE PROCEDURE add_emp(empnum BIGINT, id_contract BIGINT, sal INT, cont_day DATE, due_date DATE, cc BIGINT, p_name VARCHAR, bday DATE)
LANGUAGE plpgsql
AS $$
BEGIN
INSERT INTO employee_contract (emp_num, contract_id, contract_salary, contract_issue_date, contract_due_date, person_cc, person_name, person_birthday) 
VALUES (empnum, id_contract, sal, cont_day, due_date, cc, p_name, bday );
EXCEPTION
WHEN OTHERS THEN
RAISE EXCEPTION 'error adding employee contract';
END;
$$;

/*ADDING ASSISTANT LICENSE*/
CREATE OR REPLACE PROCEDURE add_emp(empnum BIGINT, id_contract BIGINT, sal INT, cont_day DATE, due_date DATE, cc BIGINT, p_name VARCHAR, bday DATE)
LANGUAGE plpgsql
AS $$
BEGIN
CALL add_emp(empnum, id_contract, sal, cont_day, due_date, cc, p_name, bday);
INSERT INTO assistant VALUES(id_contract);
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
	IF (NOT specialty_exist(specialty)) THEN
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

