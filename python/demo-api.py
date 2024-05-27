##
## =============================================
## ============== Bases de Dados ===============
## ============== LEI  2023/2024 ===============
## =============================================
## ============== Course Project ===============
## =============================================
## =============================================
## === Department of Informatics Engineering ===
## =========== University of Coimbra ===========
## =============================================
##
## Authors:
##   João R. Campos <jrcampos@dei.uc.pt>
##   Nuno Antunes <nmsa@dei.uc.pt>
##   University of Coimbra


import flask
import jwt
import logging
import psycopg2
import time
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
from cryptography.fernet import Fernet
import json

app = flask.Flask(__name__)

StatusCodes = {
    'success': 200,
    'api_error': 400,
    'internal_error': 500
}

def load_config(file_path="secret.key"):
    with open(file_path, "rb") as key_file:
        key = key_file.read()

    cipher_suite = Fernet(key)

    with open("config.enc", "rb") as enc_file:
        encrypted_data = enc_file.read()

    decrypted_data = cipher_suite.decrypt(encrypted_data)

    config_data = json.loads(decrypted_data.decode())

    return config_data


##########################################################
## DATABASE ACCESS
##########################################################

def db_connection():
    credentials = load_config()
    db = psycopg2.connect(
        user = credentials['user'],
        password = credentials['password'],
        host = credentials['host'],
        port = credentials['port'],
        database = credentials['database']
    )

    return db

def token_required(allowed_roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            token = None
            if "Authorization" in flask.request.headers:
                token = flask.request.headers['Authorization']
            if not token:
                return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Token is missing'}), StatusCodes['api_error']

            try:
                data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
                kwargs['user_id'] = data['username']
                if (data['type'] not in allowed_roles):
                    return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Unauthorized'}), StatusCodes['api_error']
                kwargs['user_type'] = data['type']

            except jwt.ExpiredSignatureError:
                return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Token is expired'}), StatusCodes['api_error']
            except jwt.InvalidTokenError:
                return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Token is invalid'}), StatusCodes['api_error']
            except Exception as e:
                return flask.jsonify({'status': StatusCodes['api_error'], 'errors': str(e)}), StatusCodes['api_error']

            return f(*args, **kwargs)
        return decorated
    return decorator



##########################################################
## ENDPOINTS
##########################################################


##
## POST
##
## Add patient
##
## To use it, access:
## 
## http://localhost:8080/dbproj/register/patient
##
@app.route('/dbproj/register/patient', methods=['POST'])
def add_patient():
    logger.info('POST /dbproj/register/patient')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/register/patient - payload: {payload}')

    args = ['cc', 'name', 'password', 'health_number', 'emergency_contact', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        payload['cc'] = int(payload['cc'])
        payload['health_number'] = int(payload['health_number'])
        payload['emergency_contact'] = int(payload['emergency_contact'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid cc, health_number or emergency_contact'}
        return flask.jsonify(response), response['status']

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    statement = 'CALL add_patient(%s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['name'], hashed_password, payload['health_number'], payload['emergency_contact'], payload['birthday'], payload['email'],)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)

        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['cc']}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/register/patient - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Add assistant
##
## To use it, access:
## 
## http://localhost:8080/dbproj/register/assistant
##
@app.route('/dbproj/register/assistant', methods=['POST'])
def add_assistant():
    logger.info('POST /dbproj/register/assistant')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/register/assistant - payload: {payload}')

    # validate every argument
    args = ['cc', 'name', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        payload['cc'] = int(payload['cc'])
        payload['contract_id'] = int(payload['contract_id'])
        payload['salary'] = int(payload['salary'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid cc, contract_id or salary'}
        return flask.jsonify(response), response['status']

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'CALL add_assistant(%s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['name'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'],)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['email']}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/register/assistant - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Add nurse
##
## To use it, access:
## 
## http://localhost:8080/dbproj/register/nurse
##
@app.route('/dbproj/register/nurse', methods=['POST'])
def add_nurse():
    logger.info('POST /dbproj/register/nurse')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/register/nurse - payload: {payload}')

    # validate every argument
    args = ['cc', 'name', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        payload['cc'] = int(payload['cc'])
        payload['contract_id'] = int(payload['contract_id'])
        payload['salary'] = int(payload['salary'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid cc, contract_id or salary'}
        return flask.jsonify(response), response['status']
    
    if ('superior_email' not in payload):
        payload['superior_email'] = None

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'CALL add_nurse(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['name'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'], payload['superior_email'],)

    conn = db_connection()
    cur = conn.cursor()

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['email']}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/register/nurse - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Add doctor
##
## To use it, access:
## 
## http://localhost:8080/dbproj/register/doctor
##
@app.route('/dbproj/register/doctor', methods=['POST'])
def add_doctor():
    logger.info('POST /dbproj/register/doctor')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/register/doctor - payload: {payload}')

    # validate every argument
    args = ['cc', 'name', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email', 'license_id', 'license_issue_date', 'license_due_date', 'specialty_name']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        payload['cc'] = int(payload['cc'])
        payload['contract_id'] = int(payload['contract_id'])
        payload['salary'] = int(payload['salary'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid cc, contract_id or salary'}
        return flask.jsonify(response), response['status']

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'CALL add_doctor(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['name'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'], payload['license_id'], payload['license_issue_date'], payload['license_due_date'], payload['license_company'], payload['specialty_name'],)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['email']}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/register/doctor - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## PUT
##
## User login
## 
## For patients username = cc
## For employees username = email
##
## To use it, access:
## 
## http://localhost:8080/dbproj/user
##
@app.route('/dbproj/user', methods=['PUT'])
def login():
    logger.info('PUT /dbproj/user')
    payload = flask.request.get_json()

    logger.debug(f'PUT /dbproj/user - payload: {payload}')

    # validate every argument
    args = ['username', 'password']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']

    is_patient = True
    try:
        int(payload['username'])
    except ValueError:
        is_patient = False

    if (is_patient):
        statement = 'SELECT hashcode \
                    FROM patient \
                    WHERE cc = %s'
    else:
        statement = 'SELECT * FROM login_employee(%s)'

    value = (payload['username'],)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, value)

        if (is_patient):
            user_type = 'patient'
            hashcode = cur.fetchone()[0]
            if not hashcode:
                response = {'status': StatusCodes['api_error'], 'errors': 'User not found'}
                return flask.jsonify(response), response['status']
        else:
            user_type, hashcode = cur.fetchone()

        if not check_password_hash(hashcode, payload['password']):
            response = {'status': StatusCodes['api_error'], 'errors': 'Invalid password'}
            return flask.jsonify(response), response['status']

        if not user_type:
            response = {'status': StatusCodes['api_error'], 'errors': 'User not found'}
            return flask.jsonify(response), response['status']

        # generate token
        token = jwt.encode({'username': payload['username'], 'type': user_type, 'exp': time.time() + 900}, app.config['SECRET_KEY'], algorithm='HS256')

        response = {'status': StatusCodes['success'], 'results': token}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/user - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Schedule appointment
##
## Only patients can use this endpoint
##
## To use it, access:
## 
## http://localhost:8080/dbproj/appointment
##
@app.route('/dbproj/appointment', methods=['POST'])
@token_required(['patient'])
def schedule_appointment(user_id, user_type):
    logger.info('POST /dbproj/appointment')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/appointment - payload: {payload}, token_id: {user_id}, token_type: {user_type}')

    # validate every argument
    args = ['doctor_id', 'appointment_time']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']

    statement = '''
        LOCK TABLE appointment IN EXCLUSIVE MODE;
        LOCK TABLE surgery IN EXCLUSIVE MODE;
    '''
    # parameterized queries, good for security and performance
    if ('nurses' in payload and payload['nurses'] != []):
        nurse_ids = []
        nurse_roles = []
        try:
            for nurse in payload['nurses']:
                nurse_ids.append(nurse[0])
                nurse_roles.append(nurse[1])
        except IndexError:
            response = {'status': StatusCodes['api_error'], 'errors': 'Invalid nurse information'}
            return flask.jsonify(response), response['status']

        statement += 'SELECT schedule_appointment(%s, %s, %s, %s, %s)'
        values = (payload['appointment_time'], payload['doctor_id'], user_id, nurse_ids, nurse_roles,)
    else:
        statement += 'SELECT schedule_appointment(%s, %s, %s)'
        values = (payload['appointment_time'], payload['doctor_id'], user_id,)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)
        appointment_id = cur.fetchone()[0]

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': appointment_id}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/appointment - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## GET
##
## See appointments
## 
## Only assistants and the target patient can use this endpoint
##
## To use it, access:
## 
## http://localhost:8080/dbproj/appointments/<patient_user_id>
##
@app.route('/dbproj/appointments/<patient_user_id>', methods=['GET'])
@token_required(['assistant', 'patient'])
def get_appointments(patient_user_id, user_id, user_type):
    logger.info('GET /dbproj/appointments/<patient_user_id>')

    logger.debug(f'patient_user_id: {patient_user_id}, token_id: {user_id}, token_type: {user_type}')

    try:
        patient_user_id = int(patient_user_id)
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid patient_user_id'}
        return flask.jsonify(response), response['status']

    if (user_type == 'patient' and user_id != patient_user_id):
        response = {'status': StatusCodes['api_error'], 'errors': 'Unauthorized'}
        return flask.jsonify(response), response['status']
    
    statement = 'SELECT a.id, e.emp_num, a.start_time \
                FROM appointment AS a, employee AS e \
                WHERE a.patient_cc = %s AND a.doctor_email = e.email'
    value = (patient_user_id,)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, value)
        rows = cur.fetchall()

        appointments = []
        for row in rows:
            appointments.append({'id': int(row[0]), 'doctor_id': int(row[1]), 'start_time': row[2]})

        response = {'status': StatusCodes['success'], 'results': appointments}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /dbproj/appointments/<patient_user_id> - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Schedule surgery
## 
## Only assistants can use this endpoint
##
## To use it, access:
## 
## http://localhost:8080/dbproj/surgery
## OR
## http://localhost:8080/dbproj/surgery/<int:hospitalization_id>
##
## If the hospitalization_id is provided, the surgery will be associated to that hospitalization
##
@app.route('/dbproj/surgery', methods=['POST'], defaults={'hospitalization_id': None})
@app.route('/dbproj/surgery/<int:hospitalization_id>', methods=['POST'])
@token_required(['assistant'])
def schedule_surgery(hospitalization_id, user_id, user_type):
    if (hospitalization_id):
        logger.info(f'POST /dbproj/surgery/{hospitalization_id}')
    else:
        logger.info('POST /dbproj/surgery')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/surgery - payload: {payload}, token_id: {user_id}, token_type: {user_type}')

    # validate every argument
    if (hospitalization_id):
        args = ['patient_id', 'doctor', 'nurses', 'surgery_start', 'surgery_end']
    else:
        args = ['patient_id', 'doctor', 'nurses', 'surgery_start', 'surgery_end', 'hospitalization_entry_time', 'hospitalization_exit_time', 'hospitalization_responsable_nurse']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    
    try:
        payload['patient_id'] = int(payload['patient_id'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid patient_id'}
        return flask.jsonify(response), response['status']

    nurse_ids = []
    nurse_roles = []
    try:
        for nurse in payload['nurses']:
            nurse_ids.append(nurse[0])
            nurse_roles.append(nurse[1])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid nurse id'}
        return flask.jsonify(response), response['status']
    except IndexError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid nurse information'}
        return flask.jsonify(response), response['status']

    statement = '''
        LOCK TABLE appointment IN EXCLUSIVE MODE;
        LOCK TABLE surgery IN EXCLUSIVE MODE;
    '''
    if (hospitalization_id):
        statement += 'SELECT * FROM schedule_surgery(%s, %s, %s, %s, %s, %s, %s)'
        values = (payload['patient_id'], payload['doctor'], nurse_ids, nurse_roles, payload['surgery_start'], payload['surgery_end'], hospitalization_id,)
    else:
        statement += 'SELECT * FROM schedule_surgery(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
        values = (payload['patient_id'], payload['doctor'], nurse_ids, nurse_roles, payload['surgery_start'], payload['surgery_end'], None, payload['hospitalization_entry_time'], payload['hospitalization_exit_time'], payload['hospitalization_responsable_nurse'],)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)
        surgery_id, hospitalization_id, bill_id = cur.fetchone()

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': {
            'surgery_id': surgery_id, 
            'hospitalization_id': hospitalization_id, 
            'bill_id': bill_id, 
            'patient_id': payload['patient_id'], 
            'doctor_id': payload['doctor'], 
            'date': payload['surgery_start']}
        }

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/surgery - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Execute payment
##
## Only the patient can pay his/her own bills
##
## To use it, access:
##
## http://localhost:8080/dbproj/bills/<bill_id>
##
@app.route('/dbproj/bills/<bill_id>', methods=['POST'])
@token_required(['patient'])
def execute_payment(bill_id, user_id, user_type):
    logger.info('POST /dbproj/bills/<bill_id>')
    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/bills/{bill_id} - payload: {payload}, token_id: {user_id}, token_type: {user_type}')

    args = ['amount', 'payment_method']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        bill_id = int(bill_id)
        payload['amount'] = int(payload['amount']) # amount only accepts integers (no cents)
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid bill_id or amount'}
        return flask.jsonify(response), response['status']
    
    statement = 'SELECT execute_payment(%s, %s, %s, %s)'
    values = (bill_id, payload['amount'], payload['payment_method'], user_id,)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)
        remaining_amount = cur.fetchone()[0]

        response = {'status': StatusCodes['success'], 'results': remaining_amount}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/bills/<bill_id> - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()        

    return flask.jsonify(response), response['status']


##
## GET
##
## Daily Summary
##
## Only assistants can use this endpoint
##
## To use it, access:
##
## http://localhost:8080/dbproj/daily/<year-month-day>
##
@app.route('/dbproj/daily/<date>', methods=['GET'])
@token_required(['assistant'])
def daily_summary(date, user_id, user_type):
    logger.info(f'GET /dbproj/daily/<date>')

    logger.debug(f'GET /dbproj/daily/{date} - token_id: {user_id}, token_type: {user_type}')

    statement = '''
        SELECT
            COALESCE(SUM(hms.total_amount_spent), 0) AS amount_spent,
            COALESCE(SUM(hc.surgery_count), 0) AS surgeries,
            COALESCE(SUM(hc.prescription_count), 0) AS prescriptions
        FROM hospitalization AS h
        LEFT JOIN hospitalization_counts AS hc ON h.id = hc.id
        LEFT JOIN hospitalization_money_spent AS hms ON h.id = hms.id
        WHERE h.entry_time::date = %s;
    '''
    values = (date,)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, values)
        amount_spent, surgeries, prescriptions = cur.fetchone()

        response = {'status': StatusCodes['success'], 'results': {'amount_spent': amount_spent, 'surgeries': surgeries, 'prescriptions': prescriptions}}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/daily/<date> - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()        

    return flask.jsonify(response), response['status']


##
## GET
##
## Generate monthly reports
##
## Only assistants can use this endpoint
##
## To use it, access: 
##
## http://localhost:8080/dbproj/report
##
@app.route('/dbproj/report', methods=['GET'])
@token_required(['assistant'])
def generate_monthly_report(user_id, user_type):
    logger.info('GET /dbproj/report')

    logger.debug(f'token_id: {user_id}, token_type: {user_type}')

    statement = '''
        LOCK TABLE surgery IN SHARE MODE;
        SELECT dms.surgery_month, e.name, dms.surgery_count
        FROM doctor_monthly_surgeries AS dms
        JOIN max_monthly_surgery_count AS month_maxs
            ON dms.surgery_month = month_maxs.surgery_month
            AND dms.surgery_count = month_maxs.max_surgery_count
        JOIN employee AS e
            ON dms.doctor_email = e.email
        ORDER BY dms.surgery_month;
    '''

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement)
        rows = cur.fetchall()

        results = []
        last_month = None
        for row in rows:
            if (last_month != row[0]):
                results.append({'month': row[0], 'doctor_name': row[1], 'surgeries': row[2]})
            else:
                results[-1]['doctor_name'] += ', ' + row[1]
            last_month = row[0]

        response = {'status': StatusCodes['success'], 'results': results}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /dbproj/report - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## GET
##
## List Top 3 patients
##
## Only assistants can use this endpoint
##
## To use it, access: 
##
## http://localhost:8080/dbproj/top3
##
@app.route('/dbproj/top3', methods=['GET'])
def get_top3():
    logger.info('GET /dbproj/top3')

    conn = db_connection()
    cur = conn.cursor()

    statement = '''
        WITH MonthlyPayments AS (
            SELECT
                p.cc AS patient_id,
                SUM(pay.amount) AS total_amount
            FROM
                payment pay
                LEFT JOIN appointment a ON a.bill_id = pay.bill_id
                LEFT JOIN hospitalization h ON h.bill_id = pay.bill_id
                LEFT JOIN patient p ON p.cc = a.patient_cc OR p.cc = h.patient_cc
            WHERE 
                EXTRACT(YEAR FROM pay.date_time) = EXTRACT(YEAR FROM CURRENT_DATE)
                AND EXTRACT(MONTH FROM pay.date_time) = EXTRACT(MONTH FROM CURRENT_DATE)
            GROUP BY 
                p.cc
        ),
        TopPatients AS (
            SELECT
                patient_id,
                total_amount
            FROM 
                MonthlyPayments
            ORDER BY 
                total_amount DESC
            LIMIT 3
        )
        SELECT 
            patient.name AS patient_name,
            patient.cc AS patient_id,
            tp.total_amount AS total_amount,

            appointment.id AS appointment_id,
            appointment.start_time AS appointment_start,
            appointment_doctor.name AS doctor_name,
            appointment_doctor.email AS doctor_id,
            appointment_nurse.name AS nurse_name,

            surgery.id AS surgery_id,
            surgery.start_time AS surgery_start,
            surgery_doctor.name AS surgery_doctor,
            surgery_doctor.email AS surgery_doctor_id,
            surgery_nurse.name AS surgery_nurse,
            surgery_nurse.email AS surgery_nurse_id
        FROM 
            TopPatients tp
            JOIN patient ON tp.patient_id = patient.cc
            LEFT JOIN appointment ON patient.cc = appointment.patient_cc
            LEFT JOIN employee appointment_doctor ON appointment_doctor.email = appointment.doctor_email
            LEFT JOIN appointment_role ON appointment.id = appointment_role.appointment_id
            LEFT JOIN employee appointment_nurse ON appointment_role.nurse_email = appointment_nurse.email
            LEFT JOIN hospitalization ON patient.cc = hospitalization.patient_cc
            LEFT JOIN surgery ON hospitalization.id = surgery.hospitalization_id
            LEFT JOIN surgery_role ON surgery.id = surgery_role.surgery_id
            LEFT JOIN employee surgery_nurse ON surgery_nurse.email = surgery_role.nurse_email
            LEFT JOIN employee surgery_doctor ON surgery_doctor.email = surgery.doctor_email
        ORDER BY 
            tp.total_amount, patient_id, hospitalization.id, surgery.id DESC;
    '''

    try:
        cur.execute(statement)
        rows = cur.fetchall()
        logger.debug('GET /dbproj/top3 - parse')
        i = 0
        result = [] 
        appointment_idx = 3
        surgery_idx = 7
        while i < len(rows):
            client = rows[i][0]
            total_amount = rows[i][1]
            result.append({'client': client, 'total_amount': total_amount, 'procedures': []})
            while i < len(rows) and rows[i][0] == client:
                if rows[i][appointment_idx]:
                    result[-1]['procedures'].append({'type': 'appointment', 'id': rows[i][appointment_idx], 'start_time': rows[i][appointment_idx + 1], 'doctor_email': rows[i][appointment_idx + 2], 'nurses_email': rows[i][appointment_idx + 3]})
                    i += 1
                    while i < len(rows) and rows[i][appointment_idx] == result[-1]['procedures'][-1]['id']:
                        result[-1]['procedures'][-1]['nurses_email'].append(rows[i][appointment_idx + 3])
                        i += 1
                    continue
                if rows[i][surgery_idx]:
                    surg_id = rows[i][surgery_idx]
                    result[-1]['procedures'].append({'type': 'surgery', 'id': rows[i][surgery_idx], 'start_time': rows[i][surgery_idx + 1], 'doctor_email': rows[i][surgery_idx + 2], 'nurses_email': rows[i][surgery_idx + 3]})
                    i += 1
                    while i < len(rows) and rows[i][surgery_idx] == surg_id:
                        result[-1]['procedures'][-1]['nurses_email'].append(rows[i][surgery_idx + 3])
                        i += 1
                    continue

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /departments/<ndep> - error: {error}')
        result = {'status': StatusCodes['internal_error'], 'errors': str(error)}

    finally:
        if conn is not None:
            conn.close()
    return flask.jsonify(result)



def validate_medicines_payload(payload):
    for medicine in payload['medicines']:
        if not validate_medicine(medicine):
            return {'status': StatusCodes['api_error'], 'results': 'Invalid medicine payload'}, StatusCodes['api_error']
    return None, StatusCodes['success']

def validate_medicine(medicine):
    required_fields = ['name', 'posology_dose', 'posology_frequency']
    for field in required_fields:
        if field not in medicine:
            return False
    if 'side_effects' in medicine and not validate_side_effects(medicine['side_effects']):
        return False
    return True

def validate_side_effects(side_effects):
    for side_effect in side_effects:
        required_fields = ['occurrence', 'description', 'severity']
        for field in required_fields:
            if field not in side_effect:
                return False
    return True


##
## GET
##
## Get Prescriptions
##
## Only employees and the target patient can use this endpoint
##
## To use it, access:
##
## http://localhost:8080/dbproj/prescriptions/<person_id>
##
@app.route('/dbproj/prescriptions/<person_id>', methods=['GET'])
@token_required(['assistant', 'nurse', 'doctor', 'patient'])
def get_prescriptions(person_id, user_id, user_type):
    logger.info('GET /dbproj/prescriptions/<person_id>')

    logger.debug(f'person_id: {person_id}, token_id: {user_id}, token_type: {user_type}')

    try:
        person_id = int(person_id)
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid person_id'}
        return flask.jsonify(response), response['status']

    if (user_type == 'patient' and user_id != person_id):
        response = {'status': StatusCodes['api_error'], 'errors': 'Unauthorized'}
        return flask.jsonify(response), response['status']

    statement = '''
        SELECT p.id, p.validity, md.quantity, md.frequency, md.medicine_name
        FROM prescription AS p
        JOIN medicine_dosage AS md ON md.prescription_id = p.id
        LEFT JOIN appt_prescriptions AS ap ON ap.id = p.id
        LEFT JOIN hosp_prescriptions AS hp ON hp.id = p.id
        WHERE (ap.patient_cc = %s OR hp.patient_cc = %s)
        AND p.validity >= CURRENT_DATE
        ORDER BY p.id;
    '''
    value = (person_id, person_id,)

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(statement, value)
        rows = cur.fetchall()

        prescriptions = []
        for row in rows:
            prescriptions.append({'id': int(row[0]), 'validity': row[1], 'posology': [{'dose': row[2], 'frequency': row[3], 'medicine': row[4]}]})

        response = {'status': StatusCodes['success'], 'results': prescriptions}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /dbproj/prescriptions/<person_id> - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response), response['status']


##
## POST
##
## Add Prescription
##
## Only assistants can use this endpoint
##
## To use it, access:
##
## http://localhost:8080/dbproj/prescription
##
@app.route('/dbproj/prescription', methods=['POST'])
@token_required(['assistant'])
def add_prescription(user_id, user_type):
    logger.info('POST /dbproj/prescription')

    payload = flask.request.get_json()

    logger.debug(f'POST /dbproj/prescription - payload: {payload}, token_id: {user_id}, token_type: {user_type}')

    for arg in ['type', 'event_id', 'validity']:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'results': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']

    validation_result, status_code = validate_medicines_payload(payload)
    if validation_result is not None:
        return flask.jsonify(validation_result), status_code

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute('SELECT add_prescription(%s, %s, %s)', (payload['type'], payload['validity'], payload['event_id'],))
        prescription_id = cur.fetchone()[0]

        if prescription_id == -1:
            response = {'status': StatusCodes['api_error'], 'errors': 'Invalid event_id'}
            return flask.jsonify(response), response['status']

        response = {'status': StatusCodes['success'], 'results': prescription_id}
        for medicine in payload['medicines']:
            if ('side_effects' not in medicine):
                side_effects = ''
            else:
                side_effects = ", ".join(
                    f"({se['occurrence']}, {se['description']}, {se['severity']})" for se in medicine['side_effects']
                )

            statement = 'CALL add_medicine_with_side_effects(%s, %s, %s, %s, ARRAY[%s]::side_effect_type[])'
            values = (medicine['name'], medicine['posology_dose'], medicine['posology_frequency'], prescription_id, side_effects,)
            cur.execute(statement, values)

        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/prescription - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}
        # an error occurred, rollback
        conn.rollback()
    finally:
        if conn is not None:
            conn.close()
    return flask.jsonify(response), response['status']



##########################################################
## MAIN
##########################################################

if __name__ == '__main__':
    # set up logging
    logging.basicConfig(filename='log_file.log')
    logger = logging.getLogger('logger')
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    
    config = load_config()
    app.config['SECRET_KEY'] = config['SECRET_KEY']

    # create formatter
    formatter = logging.Formatter('%(asctime)s [%(levelname)s]:  %(message)s', '%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    host = '127.0.0.1'
    port = 8080
    app.run(host=host, debug=True, threaded=True, port=port)
    logger.info(f'API v1.0 online: http://{host}:{port}')
