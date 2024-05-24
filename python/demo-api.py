##
## =============================================
## ============== Bases de Dados ===============
## ============== LEI  2023/2024 ===============
## =============================================
## =================== Demo ====================
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

app = flask.Flask(__name__)
app.config['SECRET_KEY'] = 'jyrcv1+lR#acVxK'

StatusCodes = {
    'success': 200,
    'api_error': 400,
    'internal_error': 500
}

##########################################################
## DATABASE ACCESS
##########################################################

def db_connection():
    db = psycopg2.connect(
        user='postgres',
        password='postgres',
        host='127.0.0.1',
        port='5432',
        database='prjDB'
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

            ## TODO: check if user really exists in the database

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

    # validate every argument
    args = ['cc', 'username', 'password', 'health_number', 'emergency_contact', 'birthday', 'email']
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

    # parameterized queries, good for security and performance
    statement = 'CALL add_patient(%s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['health_number'], payload['emergency_contact'], payload['birthday'], payload['email'],)

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['cc']}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/register/patient - error: {error}')
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
    args = ['cc', 'username', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email']
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
    statement = 'SELECT add_assistant(%s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'],)

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(statement, values)
        emp_num = cur.fetchone()[0]

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': emp_num}

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
    args = ['cc', 'username', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        payload['cc'] = int(payload['cc'])
        payload['contract_id'] = int(payload['contract_id'])
        payload['salary'] = int(payload['salary'])
        if ('cc_superior' in payload):
            payload['cc_superior'] = int(payload['cc_superior'])
        else:
            payload['cc_superior'] = None
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid cc, contract_id, salary or cc_superior'}
        return flask.jsonify(response), response['status']

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'SELECT add_nurse(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'], payload['cc_superior'],)

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(statement, values)
        emp_num = cur.fetchone()[0]

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': emp_num}

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
    args = ['cc', 'username', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email', 'license_id', 'license_issue_date', 'license_due_date', 'specialty_name']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    try:
        payload['cc'] = int(payload['cc'])
        payload['contract_id'] = int(payload['contract_id'])
        payload['salary'] = int(payload['salary'])
        payload['license_id'] = int(payload['license_id'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid cc, contract_id, salary or license_id'}
        return flask.jsonify(response), response['status']

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'SELECT add_doctor(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'], payload['license_id'], payload['license_issue_date'], payload['license_due_date'], payload['license_company'], payload['specialty_name'],)

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(statement, values)
        emp_num = cur.fetchone()[0]

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': emp_num}

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
## For employees username = emp_num
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

    statement = 'SELECT hashcode \
                FROM patient \
                WHERE cc = %s'
    value = (payload['username'],)
    user_type = None

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(statement, value)
        row = cur.fetchone()

        if row and check_password_hash(row[0], payload['password']):
            user_type = 'patient'
        elif row:
            response = {'status': StatusCodes['api_error'], 'errors': 'Invalid password'}
            return flask.jsonify(response), response['status']

        for worker_type in ['assistant', 'nurse', 'doctor']:
            if (user_type):
                break
            statement = f'SELECT hashcode \
                        FROM employee \
                        JOIN {worker_type} ON {worker_type}.cc = employee.cc \
                        WHERE emp_num = %s'
            cur.execute(statement, value)
            row = cur.fetchone()
            if row and check_password_hash(row[0], payload['password']):
                user_type = worker_type
            elif row:
                response = {'status': StatusCodes['api_error'], 'errors': 'Invalid password'}
                return flask.jsonify(response), response['status']

        if not user_type:
            response = {'status': StatusCodes['api_error'], 'errors': 'User not found'}
            return flask.jsonify(response), response['status']

        # generate token
        token = jwt.encode({'username': payload['username'], 'type': user_type, 'exp': time.time() + 3600}, app.config['SECRET_KEY'], algorithm='HS256')
        
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
    try:
        payload['doctor_id'] = int(payload['doctor_id'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid doctor_id'}
        return flask.jsonify(response), response['status']

    # parameterized queries, good for security and performance
    if (payload['nurses']):
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
        
        statement = 'SELECT schedule_appointment(%s, %s, %s, %s, %s)'
        values = (payload['appointment_time'], payload['doctor_id'], user_id, nurse_ids, nurse_roles,)
    else:
        statement = 'SELECT schedule_appointment(%s, %s, %s)'
        values = (payload['appointment_time'], payload['doctor_id'], user_id,)

    conn = db_connection()
    cur = conn.cursor()

    try:
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
                WHERE a.patient_cc = %s AND a.doctor_cc = e.cc'
    value = (patient_user_id,)

    conn = db_connection()
    cur = conn.cursor()

    try:
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
        args = ['patient_id', 'doctor', 'nurses', 'surgery_time']
    else:
        args = ['patient_id', 'doctor', 'nurses', 'surgery_time', 'hospitalization_entry_time', 'hospitalization_exit_time', 'hospitalization_responsable_nurse']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response), response['status']
    
    try:
        payload['patient_id'] = int(payload['patient_id'])
        payload['doctor'] = int(payload['doctor'])
        if (not hospitalization_id):
            payload['hospitalization_entry_time'] = int(payload['hospitalization_entry_time'])
            payload['hospitalization_exit_time'] = int(payload['hospitalization_exit_time'])
            payload['hospitalization_responsable_nurse'] = int(payload['hospitalization_responsable_nurse'])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid patient_id, doctor, hospitalization_entry_time, hospitalization_exit_time or hospitalization_responsable_nurse'}
        return flask.jsonify(response), response['status']
    
    nurse_ids = []
    nurse_roles = []
    try:
        for nurse in payload['nurses']:
            id = int(nurse[0])
            nurse_ids.append(id)
            nurse_roles.append(nurse[1])
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid nurse id'}
        return flask.jsonify(response), response['status']
    except IndexError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid nurse information'}
        return flask.jsonify(response), response['status']

    print(payload['patient_id'])
    print(payload['doctor'])
    print(nurse_ids)
    print(nurse_roles)
    print(payload['surgery_time'])
    print(hospitalization_id)

    if (hospitalization_id):
        statement = 'SELECT * FROM schedule_surgery(%s, %s, %s, %s, %s, %s)'
        values = (payload['patient_id'], payload['doctor'], nurse_ids, nurse_roles, payload['surgery_time'], hospitalization_id,)
    else:
        statement = 'SELECT * FROM schedule_surgery(%s, %s, %s, %s, %s, %s, %s, %s, %s)'
        values = (payload['patient_id'], payload['doctor'], nurse_ids, nurse_roles, payload['surgery_time'], None, payload['hospitalization_entry_time'], payload['hospitalization_exit_time'], payload['hospitalization_responsable_nurse'],)

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(statement, values)
        surgery_id, hospitalization_id, bill_id = cur.fetchone()

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': {'surgery_id': surgery_id, 
                                                                  'hospitalization_id': hospitalization_id, 
                                                                  'bill_id': bill_id, 
                                                                  'patient_id': payload['patient_id'], 
                                                                  'doctor_id': payload['doctor'], 
                                                                  'date': payload['surgery_time']}}

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

    conn = db_connection()
    cur = conn.cursor()

    try:
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
            COALESCE(SUM(p.amount), 0) AS amount_spent,
            COUNT(DISTINCT s.id) AS surgeries,
            COUNT(DISTINCT hp.prescription_id) AS prescriptions
        FROM hospitalization AS h
        LEFT JOIN surgery AS s ON h.id = s.hospitalization_id
        LEFT JOIN payment AS p ON h.bill_id = p.bill_id
        LEFT JOIN hospitalization_prescription AS hp ON h.id = hp.hospitalization_id
        WHERE h.entry_time::date = %s;
    '''
    values = (date,)

    conn = db_connection()
    cur = conn.cursor()

    try:
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
        WITH monthly_surgeries AS (
            SELECT
                doctor_cc,
                TO_CHAR(DATE_TRUNC('month', start_time), 'YYYY-MM') AS surgery_month,
                COUNT(id) AS surgery_count
            FROM surgery
            WHERE start_time >= (CURRENT_DATE - INTERVAL '1 year')                      
            GROUP BY doctor_cc, DATE_TRUNC('month', start_time)                         
        )                                                                               
        SELECT m.surgery_month, e.name, surgery_count                                   
        FROM monthly_surgeries AS m                                                     
        JOIN (                                                                          
            SELECT                                                                      
                surgery_month,                                                          
                MAX(surgery_count) AS max_surgery_count                                 
            FROM monthly_surgeries                                                      
            GROUP BY surgery_month                                                      
        ) AS month_maxs                                                                 
        ON m.surgery_month = month_maxs.surgery_month                                  
            AND m.surgery_count = month_maxs.max_surgery_count                          
        JOIN employee AS e                                                           
        ON m.doctor_cc = e.cc                                                           
        ORDER BY m.surgery_month;                                                       
    '''

    conn = db_connection()
    cur = conn.cursor()

    try:
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

    # create formatter
    formatter = logging.Formatter('%(asctime)s [%(levelname)s]:  %(message)s', '%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    host = '127.0.0.1'
    port = 8080
    app.run(host=host, debug=True, threaded=True, port=port)
    logger.info(f'API v1.0 online: http://{host}:{port}')
