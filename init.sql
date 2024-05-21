CREATE TABLE doctor (
	cc	 BIGINT,
	license_id			 VARCHAR(64) NOT NULL,
	license_company_name	 VARCHAR(128),
	license_issue_date		 DATE NOT NULL,
	license_due_date		 DATE NOT NULL,
	PRIMARY KEY(cc)
);

CREATE TABLE employee (
	cc	 BIGINT,
	name	 VARCHAR(128) NOT NULL,
	hashcode	 VARCHAR(128) NOT NULL,
	emp_num		 BIGSERIAL NOT NULL,
	contract_id	 BIGINT NOT NULL,
	salary	 INTEGER NOT NULL,
	contract_issue_date	 DATE NOT NULL,
	contract_due_date	 DATE NOT NULL,
	birthday	 DATE,
	email	 VARCHAR(128),
	PRIMARY KEY(cc)
);

CREATE TABLE patient (
	cc	 BIGINT,
	name	 VARCHAR(128) NOT NULL,
	hashcode	 VARCHAR(128) NOT NULL,
	health_num	 BIGINT NOT NULL,
	emergency_contact BIGINT NOT NULL,
	birthday	 DATE,
	email	 VARCHAR(128),
	PRIMARY KEY(cc)
);

CREATE TABLE assistant (
	cc BIGINT,
	PRIMARY KEY(cc)
);

CREATE TABLE nurse (
	cc BIGINT,
	PRIMARY KEY(cc)
);

CREATE TABLE appointment (
	id					 BIGSERIAL,
	start_time			 TIMESTAMP NOT NULL,
	end_time			 TIMESTAMP NOT NULL,
	cost				 INTEGER NOT NULL,
	bill_id				 BIGINT NOT NULL,
	doctor_cc			 BIGINT NOT NULL,
	patient_cc			 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE hospitalization (
	id				 BIGSERIAL,
	entry_time			 DATE NOT NULL,
	exit_time			 DATE,
	bill_id				 BIGINT NOT NULL,
	nurse_cc		 BIGINT NOT NULL,
	patient_cc		 BIGINT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE surgery (
	id					 BIGSERIAL,
	start_time				 TIMESTAMP NOT NULL,
	duration					 TIMESTAMP,
	cost					 BIGINT,
	doctor_cc			 BIGINT NOT NULL,
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
	occurrence	 VARCHAR(512),
	description VARCHAR(512),
	PRIMARY KEY(occurrence)
);

CREATE TABLE medicine_dosage (
	quantity	 BIGINT,
	medicine_name	 BIGINT,
	prescription_id BIGINT,
	PRIMARY KEY(quantity,medicine_name,prescription_id)
);

CREATE TABLE reaction_severity (
	degree		 VARCHAR(512),
	side_effect_occurrence VARCHAR(512),
	medicine_name	 BIGINT,
	PRIMARY KEY(degree,side_effect_occurrence,medicine_name)
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

CREATE TABLE specialty (
	name VARCHAR(128),
	PRIMARY KEY(name)
);

CREATE TABLE appointment_role (
	role				 VARCHAR(512),
	appointment_id			 BIGINT,
	nurse_cc BIGINT,
	PRIMARY KEY(appointment_id,nurse_cc)
);

CREATE TABLE surgery_role (
	role				 VARCHAR(512),
	surgery_id			 BIGINT,
	nurse_cc BIGINT,
	PRIMARY KEY(surgery_id,nurse_cc)
);

CREATE TABLE specialty_hierarchy (
	specialty_name	 VARCHAR(128),
	specialty_parent VARCHAR(128) NOT NULL,
	PRIMARY KEY(specialty_name)
);

CREATE TABLE doctor_specialty (
	doctor_cc	 BIGINT,
	specialty_name		 VARCHAR(128),
	PRIMARY KEY(doctor_cc, specialty_name)
);

CREATE TABLE nurse_hierarchy (
	cc_nurse	 BIGINT,
	cc_boss		 BIGINT NOT NULL,
	PRIMARY KEY(cc_nurse)
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
ALTER TABLE doctor ADD CONSTRAINT doctor_fk1 FOREIGN KEY (cc) REFERENCES employee(cc);
ALTER TABLE employee ADD UNIQUE (emp_num, contract_id);
ALTER TABLE patient ADD UNIQUE (health_num);
ALTER TABLE assistant ADD CONSTRAINT assistant_fk1 FOREIGN KEY (cc) REFERENCES employee(cc);
ALTER TABLE nurse ADD CONSTRAINT nurse_fk1 FOREIGN KEY (cc) REFERENCES employee(cc);


ALTER TABLE appointment ADD UNIQUE (bill_id);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk2 FOREIGN KEY (doctor_cc) REFERENCES doctor(cc);
ALTER TABLE appointment ADD CONSTRAINT appointment_fk3 FOREIGN KEY (patient_cc) REFERENCES patient(cc);
ALTER TABLE hospitalization ADD UNIQUE (bill_id, patient_cc);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk2 FOREIGN KEY (nurse_cc) REFERENCES nurse(cc);
ALTER TABLE hospitalization ADD CONSTRAINT hospitalization_fk3 FOREIGN KEY (patient_cc) REFERENCES patient(cc);
ALTER TABLE surgery ADD CONSTRAINT surgery_fk1 FOREIGN KEY (doctor_cc) REFERENCES doctor(cc);
ALTER TABLE surgery ADD CONSTRAINT surgery_fk2 FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(id);
ALTER TABLE medicine_dosage ADD CONSTRAINT medicine_dosage_fk1 FOREIGN KEY (medicine_name) REFERENCES medicine(name);
ALTER TABLE medicine_dosage ADD CONSTRAINT medicine_dosage_fk2 FOREIGN KEY (prescription_id) REFERENCES prescription(id);
ALTER TABLE reaction_severity ADD CONSTRAINT reaction_severity_fk1 FOREIGN KEY (side_effect_occurrence) REFERENCES side_effect(occurrence);
ALTER TABLE reaction_severity ADD CONSTRAINT reaction_severity_fk2 FOREIGN KEY (medicine_name) REFERENCES medicine(name);
ALTER TABLE payment ADD CONSTRAINT payment_fk1 FOREIGN KEY (bill_id) REFERENCES bill(id);
ALTER TABLE appointment_role ADD CONSTRAINT appointment_role_fk1 FOREIGN KEY (appointment_id) REFERENCES appointment(id);
ALTER TABLE appointment_role ADD CONSTRAINT appointment_role_fk2 FOREIGN KEY (nurse_cc) REFERENCES nurse(cc);
ALTER TABLE surgery_role ADD CONSTRAINT surgery_role_fk1 FOREIGN KEY (surgery_id) REFERENCES surgery(id);
ALTER TABLE surgery_role ADD CONSTRAINT surgery_role_fk2 FOREIGN KEY (nurse_cc) REFERENCES nurse(cc);


ALTER TABLE specialty_hierarchy ADD CONSTRAINT specialty_hierarchy_fk1 FOREIGN KEY (specialty_name) REFERENCES specialty(name);
ALTER TABLE specialty_hierarchy ADD CONSTRAINT specialty_hierarchy_fk2 FOREIGN KEY (specialty_parent) REFERENCES specialty(name);
ALTER TABLE doctor_specialty ADD CONSTRAINT doctor_specialty_fk1 FOREIGN KEY (doctor_cc) REFERENCES doctor(cc);
ALTER TABLE doctor_specialty ADD CONSTRAINT doctor_specialty_fk2 FOREIGN KEY (specialty_name) REFERENCES specialty(name);
ALTER TABLE nurse_hierarchy ADD CONSTRAINT nurse_nurse_fk1 FOREIGN KEY (cc_nurse) REFERENCES nurse(cc);
ALTER TABLE nurse_hierarchy ADD CONSTRAINT nurse_nurse_fk2 FOREIGN KEY (cc_boss) REFERENCES nurse(cc);


ALTER TABLE hospitalization_prescription ADD CONSTRAINT hospitalization_prescription_fk1 FOREIGN KEY (prescription_id) REFERENCES prescription(id);
ALTER TABLE hospitalization_prescription ADD CONSTRAINT hospitalization_prescription_fk2 FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(id);
ALTER TABLE appointment_prescription ADD CONSTRAINT appointment_prescription_fk1 FOREIGN KEY (appointment_id) REFERENCES appointment(id);
ALTER TABLE appointment_prescription ADD CONSTRAINT appointment_prescription_fk2 FOREIGN KEY (prescription_id) REFERENCES prescription(id);

