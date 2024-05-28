CREATE TABLE doctor (
	email VARCHAR(128),
	license_id		 VARCHAR(64) NOT NULL,
	license_company_name	 VARCHAR(128),
	license_issue_date	 DATE NOT NULL,
	license_due_date	 DATE NOT NULL,
	PRIMARY KEY(email)
);

CREATE TABLE employee (
	email		 VARCHAR(128),
	emp_num		 BIGSERIAL NOT NULL,
	cc			 BIGINT NOT NULL,
	name		 VARCHAR(128) NOT NULL,
	hashcode		 VARCHAR(128) NOT NULL,
	birthday		 DATE,
	contract_id	 BIGINT NOT NULL,
	salary	 INTEGER NOT NULL,
	contract_issue_date DATE NOT NULL,
	contract_due_date	 DATE NOT NULL,
	PRIMARY KEY(email)
);
CREATE INDEX employee_cc_idx ON employee(hashcode);

CREATE TABLE patient (
	cc		 BIGINT,
	health_num	 BIGINT NOT NULL,
	name		 VARCHAR(128) NOT NULL,
	hashcode		 VARCHAR(128) NOT NULL,
	emergency_contact BIGINT NOT NULL,
	birthday		 DATE,
	email		 VARCHAR(128),
	PRIMARY KEY(cc)
);
CREATE INDEX patient_health_num_idx ON patient(hashcode);

CREATE TABLE assistant (
	email VARCHAR(128),
	PRIMARY KEY(email)
);

CREATE TABLE nurse (
	email VARCHAR(128),
	PRIMARY KEY(email)
);

CREATE TABLE appointment (
	id					 BIGSERIAL,
	start_time				 TIMESTAMP NOT NULL,
	bill_id				 BIGINT NOT NULL,
	doctor_email VARCHAR(128) NOT NULL,
	patient_cc				 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE hospitalization (
	id				 BIGSERIAL,
	entry_time			 TIMESTAMP NOT NULL,
	exit_time			 TIMESTAMP NOT NULL,
	bill_id			 BIGINT NOT NULL,
	nurse_email VARCHAR(128) NOT NULL,
	patient_cc			 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE surgery (
	id					 BIGSERIAL,
	start_time				 TIMESTAMP NOT NULL,
	end_time				 TIMESTAMP NOT NULL,
	doctor_email VARCHAR(128) NOT NULL,
	hospitalization_id			 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE prescription (
	id BIGSERIAL,
	validity DATE NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE medicine (
	name VARCHAR(128) NOT NULL,
	PRIMARY KEY(name)
);

CREATE TABLE side_effect (
	occurrence	 VARCHAR(512),
	description VARCHAR(512),
	PRIMARY KEY(occurrence)
);

CREATE TABLE medicine_dosage (
	quantity	 VARCHAR(128) NOT NULL,
	frequency	 VARCHAR(128) NOT NULL,
	medicine_name	 VARCHAR(128),
	prescription_id BIGINT,
	PRIMARY KEY(medicine_name,prescription_id)
);

CREATE TABLE reaction_severity (
	degree		 VARCHAR(128) NOT NULL,
	side_effect_occurrence VARCHAR(512),
	medicine_name	 VARCHAR(128),
	PRIMARY KEY(side_effect_occurrence,medicine_name)
);

CREATE TABLE payment (
	id	 BIGSERIAL,
	amount	 INTEGER NOT NULL,
	method	 VARCHAR(128) NOT NULL,
	date_time TIMESTAMP NOT NULL,
	bill_id BIGINT,
	PRIMARY KEY(id,bill_id)
);

CREATE TABLE bill (
	id	 BIGSERIAL,
	amount INTEGER NOT NULL,
	paid	 BOOL NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE specialty (
	name VARCHAR(128),
	PRIMARY KEY(name)
);

CREATE TABLE appointment_role (
	role				 VARCHAR(128),
	appointment_id			 BIGINT,
	nurse_email VARCHAR(128),
	PRIMARY KEY(appointment_id,nurse_email)
);

CREATE TABLE surgery_role (
	role				 VARCHAR(128),
	surgery_id			 BIGINT,
	nurse_email VARCHAR(128),
	PRIMARY KEY(surgery_id,nurse_email)
);

CREATE TABLE specialty_hierarchy (
	specialty_name	 VARCHAR(128),
	specialty_parent VARCHAR(128) NOT NULL,
	PRIMARY KEY(specialty_name)
);

CREATE TABLE doctor_specialty (
	doctor_email	 VARCHAR(128),
	specialty_name		 VARCHAR(128),
	PRIMARY KEY(doctor_email, specialty_name)
);

CREATE TABLE nurse_hierarchy (
	nurse_email	 VARCHAR(128),
	superior_email		 VARCHAR(128) NOT NULL,
	PRIMARY KEY(nurse_email)
);

CREATE TABLE hospitalization_prescription (
	prescription_id	 BIGINT,
	hospitalization_id BIGINT NOT NULL,
	PRIMARY KEY(prescription_id)
);

CREATE TABLE appointment_prescription (
	appointment_id	 BIGINT NOT NULL,
	prescription_id	 BIGINT,
	PRIMARY KEY(prescription_id)
);

ALTER TABLE doctor ADD UNIQUE (license_id);
ALTER TABLE doctor ADD CONSTRAINT doctor_fk1 FOREIGN KEY (email) REFERENCES employee(email);
ALTER TABLE employee ADD UNIQUE (emp_num);
ALTER TABLE employee ADD UNIQUE (cc);
ALTER TABLE employee ADD UNIQUE (contract_id);
ALTER TABLE patient ADD UNIQUE (health_num);
ALTER TABLE assistant ADD CONSTRAINT assistant_fk1 FOREIGN KEY (email) REFERENCES employee(email);
ALTER TABLE nurse ADD CONSTRAINT nurse_fk1 FOREIGN KEY (email) REFERENCES employee(email);
ALTER TABLE appointment ADD UNIQUE (bill_id);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk2 FOREIGN KEY (doctor_email) REFERENCES doctor(email);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk3 FOREIGN KEY (patient_cc) REFERENCES patient(cc);
ALTER TABLE appointment ADD CONSTRAINT check_appointment_time CHECK (EXTRACT(MINUTE FROM start_time) IN (0, 30) AND
EXTRACT(SECOND FROM start_time) = 0);
ALTER TABLE hospitalization ADD UNIQUE (bill_id, patient_cc);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk2 FOREIGN KEY (nurse_email) REFERENCES nurse(email);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk3 FOREIGN KEY (patient_cc) REFERENCES patient(cc);
ALTER TABLE hospitalization ADD CONSTRAINT check_hospitalization_time CHECK (EXTRACT(SECOND FROM entry_time) = 0 AND
EXTRACT(SECOND FROM exit_time) = 0);
ALTER TABLE surgery ADD CONSTRAINT surgery_fk1 FOREIGN KEY (doctor_email) REFERENCES doctor(email);
ALTER TABLE surgery ADD CONSTRAINT surgery_fk2 FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(id);
ALTER TABLE surgery ADD CONSTRAINT check_surgery_time CHECK (EXTRACT(SECOND FROM start_time) = 0 AND
EXTRACT(SECOND FROM end_time) = 0);
ALTER TABLE medicine_dosage ADD CONSTRAINT medicine_dosage_fk1 FOREIGN KEY (medicine_name) REFERENCES medicine(name);
ALTER TABLE medicine_dosage ADD CONSTRAINT medicine_dosage_fk2 FOREIGN KEY (prescription_id) REFERENCES prescription(id);
ALTER TABLE reaction_severity ADD CONSTRAINT reaction_severity_fk1 FOREIGN KEY (side_effect_occurrence) REFERENCES side_effect(occurrence);
ALTER TABLE reaction_severity ADD CONSTRAINT reaction_severity_fk2 FOREIGN KEY (medicine_name) REFERENCES medicine(name);
ALTER TABLE payment ADD CONSTRAINT payment_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE appointment_role ADD CONSTRAINT appointment_role_fk1 FOREIGN KEY (appointment_id) REFERENCES appointment(id);
ALTER TABLE appointment_role ADD CONSTRAINT appointment_role_fk2 FOREIGN KEY (nurse_email) REFERENCES nurse(email);
ALTER TABLE surgery_role ADD CONSTRAINT surgery_role_fk1 FOREIGN KEY (surgery_id) REFERENCES surgery(id);
ALTER TABLE surgery_role ADD CONSTRAINT surgery_role_fk2 FOREIGN KEY (nurse_email) REFERENCES nurse(email);
ALTER TABLE specialty_hierarchy ADD CONSTRAINT specialty_hierarchy_fk1 FOREIGN KEY (specialty_name) REFERENCES specialty(name);
ALTER TABLE specialty_hierarchy ADD CONSTRAINT specialty_hierarchy_fk2 FOREIGN KEY (specialty_parent) REFERENCES specialty(name);
ALTER TABLE doctor_specialty ADD CONSTRAINT doctor_specialty_fk1 FOREIGN KEY (doctor_email) REFERENCES doctor(email);
ALTER TABLE doctor_specialty ADD CONSTRAINT doctor_specialty_fk2 FOREIGN KEY (specialty_name) REFERENCES specialty(name);
ALTER TABLE nurse_hierarchy ADD CONSTRAINT nurse_nurse_fk1 FOREIGN KEY (nurse_email) REFERENCES nurse(email);
ALTER TABLE nurse_hierarchy ADD CONSTRAINT nurse_nurse_fk2 FOREIGN KEY (superior_email) REFERENCES nurse(email);
ALTER TABLE hospitalization_prescription ADD CONSTRAINT hospitalization_prescription_fk1 FOREIGN KEY (prescription_id) REFERENCES prescription(id);
ALTER TABLE hospitalization_prescription ADD CONSTRAINT hospitalization_prescription_fk2 FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(id);
ALTER TABLE appointment_prescription ADD CONSTRAINT appointment_prescription_fk1 FOREIGN KEY (appointment_id) REFERENCES appointment(id);
ALTER TABLE appointment_prescription ADD CONSTRAINT appointment_prescription_fk2 FOREIGN KEY (prescription_id) REFERENCES prescription(id);

