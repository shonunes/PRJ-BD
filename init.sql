CREATE TABLE doctor_license (
	license_id			 VARCHAR(64) NOT NULL,
	license_company_name	 VARCHAR(512),
	license_issue_date		 DATE,
	license_due_date		 DATE NOT NULL,
	employee_contract_person_cc BIGINT,
	PRIMARY KEY(employee_contract_person_cc)
);

CREATE TABLE employee_contract (
	emp_num		 BIGSERIAL NOT NULL,
	contract_id	 BIGINT NOT NULL,
	contract_salary	 INTEGER NOT NULL,
	contract_issue_date DATE,
	contract_due_date	 DATE NOT NULL,
	person_cc		 BIGINT,
	person_name	 BOOL NOT NULL,
	person_birthday	 DATE,
	PRIMARY KEY(person_cc)
);

CREATE TABLE patient (
	health_num	 BIGINT NOT NULL,
	emergency_contact VARCHAR(512) NOT NULL,
	person_cc	 BIGINT,
	person_name	 VARCHAR(512) NOT NULL,
	person_birthday	 DATE,
	PRIMARY KEY(person_cc)
);

CREATE TABLE assistant (
	employee_contract_person_cc BIGINT,
	PRIMARY KEY(employee_contract_person_cc)
);

CREATE TABLE nurse (
	employee_contract_person_cc BIGINT,
	PRIMARY KEY(employee_contract_person_cc)
);

CREATE TABLE appointment (
	id					 BIGSERIAL,
	start_time				 TIMESTAMP NOT NULL,
	duration					 TIMESTAMP,
	cost					 INTEGER NOT NULL,
	bill_id					 BIGINT NOT NULL,
	doctor_license_employee_contract_person_cc BIGINT NOT NULL,
	patient_person_cc				 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE hospitalization (
	id				 BIGSERIAL,
	entry_date			 DATE NOT NULL,
	bill_id				 BIGINT NOT NULL,
	nurse_employee_contract_person_cc BIGINT NOT NULL,
	patient_person_cc		 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE surgery (
	id					 BIGSERIAL,
	start_time				 TIMESTAMP NOT NULL,
	duration					 TIMESTAMP,
	cost					 BIGINT,
	doctor_license_employee_contract_person_cc BIGINT NOT NULL,
	hospitalization_id			 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE prescription (
	id BIGSERIAL,
	PRIMARY KEY(id)
);

CREATE TABLE medicine (
	name BIGINT,
	PRIMARY KEY(name)
);

CREATE TABLE side_effect (
	occurency	 VARCHAR(512),
	description VARCHAR(512),
	PRIMARY KEY(occurency)
);

CREATE TABLE medicine_dosage (
	quantity	 BIGINT,
	medicine_name	 BIGINT,
	prescription_id BIGINT,
	PRIMARY KEY(quantity,medicine_name,prescription_id)
);

CREATE TABLE reaction_severity (
	degree		 VARCHAR(512),
	side_effect_occurency VARCHAR(512),
	medicine_name	 BIGINT,
	PRIMARY KEY(degree,side_effect_occurency,medicine_name)
);

CREATE TABLE payment (
	id	 BIGINT,
	amount	 INTEGER,
	bill_id BIGINT,
	PRIMARY KEY(id,bill_id)
);

CREATE TABLE bill (
	id	 BIGINT,
	amount INTEGER NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE especiality (
	name VARCHAR(512),
	PRIMARY KEY(name)
);

CREATE TABLE appointment_role (
	role				 VARCHAR(512),
	appointment_id			 BIGINT,
	nurse_employee_contract_person_cc BIGINT,
	PRIMARY KEY(appointment_id,nurse_employee_contract_person_cc)
);

CREATE TABLE surgery_role (
	role				 VARCHAR(512),
	surgery_id			 BIGINT,
	nurse_employee_contract_person_cc BIGINT,
	PRIMARY KEY(surgery_id,nurse_employee_contract_person_cc)
);

CREATE TABLE especiality_especiality (
	especiality_name	 VARCHAR(512),
	especiality_name1 VARCHAR(512) NOT NULL,
	PRIMARY KEY(especiality_name)
);

CREATE TABLE doctor_license_especiality (
	doctor_license_employee_contract_person_cc BIGINT,
	especiality_name				 VARCHAR(512),
	PRIMARY KEY(doctor_license_employee_contract_person_cc,especiality_name)
);

CREATE TABLE nurse_nurse (
	nurse_employee_contract_person_cc	 BIGINT,
	nurse_employee_contract_person_cc1 BIGINT NOT NULL,
	PRIMARY KEY(nurse_employee_contract_person_cc)
);

CREATE TABLE prescription_hospitalization (
	prescription_id	 BIGINT,
	hospitalization_id BIGINT NOT NULL,
	PRIMARY KEY(prescription_id)
);

CREATE TABLE appointment_prescription (
	appointment_id	 BIGINT NOT NULL,
	prescription_id BIGINT,
	PRIMARY KEY(prescription_id)
);

ALTER TABLE doctor_license ADD UNIQUE (license_id);
ALTER TABLE doctor_license ADD CONSTRAINT doctor_license_fk1 FOREIGN KEY (employee_contract_person_cc) REFERENCES employee_contract(person_cc);
ALTER TABLE employee_contract ADD UNIQUE (emp_num, contract_id);
ALTER TABLE patient ADD UNIQUE (health_num);
ALTER TABLE assistant ADD CONSTRAINT assistant_fk1 FOREIGN KEY (employee_contract_person_cc) REFERENCES employee_contract(person_cc);
ALTER TABLE nurse ADD CONSTRAINT nurse_fk1 FOREIGN KEY (employee_contract_person_cc) REFERENCES employee_contract(person_cc);
ALTER TABLE appointment ADD UNIQUE (bill_id);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk2 FOREIGN KEY (doctor_license_employee_contract_person_cc) REFERENCES doctor_license(employee_contract_person_cc);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk3 FOREIGN KEY (patient_person_cc) REFERENCES patient(person_cc);
ALTER TABLE hospitalization ADD UNIQUE (bill_id, patient_person_cc);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk2 FOREIGN KEY (nurse_employee_contract_person_cc) REFERENCES nurse(employee_contract_person_cc);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk3 FOREIGN KEY (patient_person_cc) REFERENCES patient(person_cc);
ALTER TABLE surgery ADD CONSTRAINT surgery_fk1 FOREIGN KEY (doctor_license_employee_contract_person_cc) REFERENCES doctor_license(employee_contract_person_cc);
ALTER TABLE surgery ADD CONSTRAINT surgery_fk2 FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(id);
ALTER TABLE medicine_dosage ADD CONSTRAINT medicine_dosage_fk1 FOREIGN KEY (medicine_name) REFERENCES medicine(name);
ALTER TABLE medicine_dosage ADD CONSTRAINT medicine_dosage_fk2 FOREIGN KEY (prescription_id) REFERENCES prescription(id);
ALTER TABLE reaction_severity ADD CONSTRAINT reaction_severity_fk1 FOREIGN KEY (side_effect_occurency) REFERENCES side_effect(occurency);
ALTER TABLE reaction_severity ADD CONSTRAINT reaction_severity_fk2 FOREIGN KEY (medicine_name) REFERENCES medicine(name);
ALTER TABLE payment ADD CONSTRAINT payment_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE appointment_role ADD CONSTRAINT appointment_role_fk1 FOREIGN KEY (appointment_id) REFERENCES appointment(id);
ALTER TABLE appointment_role ADD CONSTRAINT appointment_role_fk2 FOREIGN KEY (nurse_employee_contract_person_cc) REFERENCES nurse(employee_contract_person_cc);
ALTER TABLE surgery_role ADD CONSTRAINT surgery_role_fk1 FOREIGN KEY (surgery_id) REFERENCES surgery(id);
ALTER TABLE surgery_role ADD CONSTRAINT surgery_role_fk2 FOREIGN KEY (nurse_employee_contract_person_cc) REFERENCES nurse(employee_contract_person_cc);
ALTER TABLE especiality_especiality ADD CONSTRAINT especiality_especiality_fk1 FOREIGN KEY (especiality_name) REFERENCES especiality(name);
ALTER TABLE especiality_especiality ADD CONSTRAINT especiality_especiality_fk2 FOREIGN KEY (especiality_name1) REFERENCES especiality(name);
ALTER TABLE doctor_license_especiality ADD CONSTRAINT doctor_license_especiality_fk1 FOREIGN KEY (doctor_license_employee_contract_person_cc) REFERENCES doctor_license(employee_contract_person_cc);
ALTER TABLE doctor_license_especiality ADD CONSTRAINT doctor_license_especiality_fk2 FOREIGN KEY (especiality_name) REFERENCES especiality(name);
ALTER TABLE nurse_nurse ADD CONSTRAINT nurse_nurse_fk1 FOREIGN KEY (nurse_employee_contract_person_cc) REFERENCES nurse(employee_contract_person_cc);
ALTER TABLE nurse_nurse ADD CONSTRAINT nurse_nurse_fk2 FOREIGN KEY (nurse_employee_contract_person_cc1) REFERENCES nurse(employee_contract_person_cc);
ALTER TABLE prescription_hospitalization ADD CONSTRAINT prescription_hospitalization_fk1 FOREIGN KEY (prescription_id) REFERENCES prescription(id);
ALTER TABLE prescription_hospitalization ADD CONSTRAINT prescription_hospitalization_fk2 FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(id);
ALTER TABLE appointment_prescription ADD CONSTRAINT appointment_prescription_fk1 FOREIGN KEY (appointment_id) REFERENCES appointment(id);
ALTER TABLE appointment_prescription ADD CONSTRAINT appointment_prescription_fk2 FOREIGN KEY (prescription_id) REFERENCES prescription(id);

