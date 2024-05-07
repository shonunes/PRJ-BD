CREATE OR REPLACE PROCEDURE see_appointments(cc_num BIGINT)
LANGUAGE PLPGSQL
AS $$
BEGIN
    SELECT a.id, a.doctor_license_employee_contract_person_cc, a.start_time
    FROM appointment AS a
    WHERE a.patient_person_cc = cc_num;
END;
$$;

