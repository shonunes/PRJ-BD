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
import flask.sessions
import jwt
import logging
import psycopg2
import time
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




##########################################################
## ENDPOINTS
##########################################################


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
            return flask.jsonify(response)

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
            return flask.jsonify(response)
        int(payload['username'])
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
                response = {'status': StatusCodes['api_error'], 'errors': 'Invalid username or password'}
                return flask.jsonify(response)

        if not user_type:
            response = {'status': StatusCodes['api_error'], 'errors': 'Invalid username or password'}
            return flask.jsonify(response)

        # generate token
        token = jwt.encode({'username': payload['username'], 'type': user_type, 'exp': time.time() + 600}, app.config['SECRET_KEY'], algorithm='HS256')

        response = {'status': StatusCodes['success'], 'results': token}


        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /dbproj/user - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()
    except ValueError:
        response = {'status': StatusCodes['api_error'], 'errors': 'Invalid username or password'}
        return flask.jsonify(response)
    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)

##Check if user is logged´
def check_authentication(func):
    def checked(request):
        token = flask.headers.get('Authorization')
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        except jwt.InvalidTokenError:
            return flask.jsonify({"status": 401, "errors": "Unauthorized"}), 401
        if data is None:
            return flask.jsonify({"status": 401, "errors": "Unauthorized"}), 401
        return func(request)
    return checked


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
            return flask.jsonify(response)

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

    return flask.jsonify(response)


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
            return flask.jsonify(response)

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

    return flask.jsonify(response)


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

    # validate every argument (boss_cc not included because it is optional)
    args = ['cc', 'username', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'errors': f'{arg} value not in payload'}
            return flask.jsonify(response)
    if 'cc_superior' not in payload:
        cc_superior = None
    else:
        cc_superior = payload['cc_superior']
    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'SELECT add_nurse(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'], cc_superior,)

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

    return flask.jsonify(response)


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
            return flask.jsonify(response)

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

    return flask.jsonify(response)


##
## GET
##
## Appointments of a patient
##
## To use it, access:
## 
## http://localhost:8080/dbproj/appointment/<patient_user_id>
##

@app.route('/dbproj/appointment/<patient_cc>/', methods=['GET'])
def get_appointment(patient_cc):
    logger.info('GET /dbproj/appointment<patient_cc>/')

    logger.debug(f'<patient_user_id>: {patient_cc}')

    conn = db_connection()
    cur = conn.cursor()
    try:
        token = flask.request.headers.get('Authorization')
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
    except(jwt.InvalidTokenError):
        return flask.jsonify({"status": 401, "errors": "Unauthorized"})
    if data['type'] != 'patient' and data['type'] != 'assistant':
        return flask.jsonify({"status": 401, "errors": "Unauthorized"})
    try:
        cur.execute('SELECT id, doctor_cc, start_time FROM appointment WHERE patient_cc = %s', (patient_cc,))
        rows = cur.fetchall()

        logger.debug('GET /dbproj/appointments/<patient_user_id> - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'id': int(row[0]), 'doctor_id': row[1], 'start': row[2]}
            Results.append(content)  # appending to the payload to be returned

        response = {'status': StatusCodes['success'], 'results': Results}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /dbproj/appointments/<patient_user_id> - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)

##
## POST 
## New payment
##
@app.route('/dbproj/bills/<bill_id>', methods=['POST'])
def pay_bill(bill_id):
    try:
        token = flask.request.headers.get('Authorization')  # Assuming patient_cc is passed in headers for patient identification
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
    except jwt.InvalidTokenError:
        return flask.jsonify({"status": 401, "errors": "Unauthorized"}), 401
    if data['type'] != 'patient':
        return flask.jsonify({"status": 401, "errors": "Unauthorized"}), 401
    bill_id = int(bill_id)
    conn = db_connection()
    cur = conn.cursor()
    statement = 'SELECT SUM(amount) from payment WHERE bill_id = %s'
    values = (bill_id)
    cur.execute(statement, (bill_id, values))
    total_paid = cur.fetchone()
    total_paid = total_paid[0] if total_paid[0] else 0
    statement = 'SELECT amount from bill WHERE id = %s'
    cur.execute(statement, (bill_id,))
    rest = cur.fetchone()
    rest = rest[0] if rest[0] else 0
    remaining_value = rest - total_paid
    if remaining_value < 0:
        cur.rollback()
        return jwt.jsonify({"status": "error", "results": {"message": "Amount exceeds remaining value to pay"}}), 400
    return jwt.jsonify({"status": "success", "results": {"remaining_value": remaining_value}}), 200

##
## POST 
## New appointment
##
##
APPOINTMENT_COST = 50

@app.route('/dbproj/appointment', methods=['POST'])
def add_appointment():
    logger.info('POST /dbproj/appointment')

    payload = flask.request.get_json()
    conn = None  # Inicializar conn como None
    try:
        conn = db_connection()
        cur = conn.cursor()
        token = flask.request.headers.get('Authorization')
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])

        parameters = ['start_time', 'doctor_cc', 'end_time']
        for parameter in parameters:
            if parameter not in payload:
                return flask.jsonify({"status": 401, "errors": "Missing parameters"})
        if data['type'] != 'patient':
            return flask.jsonify({"status": 401, "errors": "Unauthorized"})

        # Logging for debugging purposes
        logger.info(f"Start time: {payload['start_time']}, End time: {payload['end_time']}, Doctor CC: {payload['doctor_cc']}, Patient CC: {data['username']}")

        statement = 'CALL add_appointment(%s, %s, %s, %s, %s)'
        cur.execute(statement, (payload['start_time'], payload['end_time'], APPOINTMENT_COST, payload['doctor_cc'], data['username']))
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': 'Appointment added successfully'}
    except(jwt.InvalidTokenError):
        response = {"status": 401, "errors": "Unauthorized"}
    except (Exception, psycopg2.DatabaseError) as e:
        logger.error(f'POST /dbproj/appointment - error: {e}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(e)}
        if conn:
            conn.rollback()
    finally:
        if conn is not None:
            conn.close()
    return flask.jsonify(response)

##
## Demo POST
##
## Add a new department in a JSON payload
##
## To use it, you need to use postman or curl:
##
## curl -X POST http://localhost:8080/surgery/ -H 'Content-Type: application/json' -d '{'localidade': 'Polo II', 'ndep': 100, 'nome': 'Seguranca'}'
##

@app.route('/dbproj/', methods=['POST'])
def add_surgery():
    logger.info('POST /exemplo')
    payload = flask.request.get_json()

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /exemplo - payload: {payload}')

    # do not forget to validate every argument, e.g.,:
    if 'escalao' not in payload:
        response = {'status': StatusCodes['api_error'], 'results': 'escalao value not in payload'}
        return flask.jsonify(response)

    # parameterized queries, good for security and performance
    statement = 'INSERT INTO exemplo (escalao) VALUES (%s)'
    values = (payload['escalao'],)

    try:
        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': f'Inserted exemplo {payload["escalao"]}'}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /exemplo - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)






































##
## Demo GET
##
## Obtain all departments in JSON format
##
## To use it, access:
##
## http://localhost:8080/departments/
##

@app.route('/departments/', methods=['GET'])
def get_all_departments():
    logger.info('GET /departments')

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT ndep, nome, local FROM dep')
        rows = cur.fetchall()

        logger.debug('GET /departments - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'ndep': int(row[0]), 'nome': row[1], 'localidade': row[2]}
            Results.append(content)  # appending to the payload to be returned

        response = {'status': StatusCodes['success'], 'results': Results}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /departments - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


##
## Demo GET
##
## Obtain department with ndep <ndep>
##
## To use it, access:
##
## http://localhost:8080/departments/10
##

@app.route('/departments/<ndep>/', methods=['GET'])
def get_department(ndep):
    logger.info('GET /departments/<ndep>')

    logger.debug(f'ndep: {ndep}')

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT ndep, nome, local FROM dep where ndep = %s', (ndep,))
        rows = cur.fetchall()

        row = rows[0]

        logger.debug('GET /departments/<ndep> - parse')
        logger.debug(row)
        content = {'ndep': int(row[0]), 'nome': row[1], 'localidade': row[2]}

        response = {'status': StatusCodes['success'], 'results': content}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /departments/<ndep> - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


##
## Demo POST
##
## Add a new department in a JSON payload
##
## To use it, you need to use postman or curl:
##
## curl -X POST http://localhost:8080/departments/ -H 'Content-Type: application/json' -d '{'localidade': 'Polo II', 'ndep': 100, 'nome': 'Seguranca'}'
##

@app.route('/exemplo/', methods=['POST'])
def add_departments():
    logger.info('POST /exemplo')
    payload = flask.request.get_json()

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /exemplo - payload: {payload}')

    # do not forget to validate every argument, e.g.,:
    if 'escalao' not in payload:
        response = {'status': StatusCodes['api_error'], 'results': 'escalao value not in payload'}
        return flask.jsonify(response)

    # parameterized queries, good for security and performance
    statement = 'INSERT INTO exemplo (escalao) VALUES (%s)'
    values = (payload['escalao'],)

    try:
        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': f'Inserted exemplo {payload["escalao"]}'}

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /exemplo - error: {error}')
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


##
## Demo PUT
##
## Update a department based on a JSON payload
##
## To use it, you need to use postman or curl:
##
## curl -X PUT http://localhost:8080/departments/ -H 'Content-Type: application/json' -d '{'ndep': 100, 'localidade': 'Porto'}'
##

@app.route('/departments/<ndep>', methods=['PUT'])
def update_departments(ndep):
    logger.info('PUT /departments/<ndep>')
    payload = flask.request.get_json()

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'PUT /departments/<ndep> - payload: {payload}')

    # do not forget to validate every argument, e.g.,:
    if 'localidade' not in payload:
        response = {'status': StatusCodes['api_error'], 'results': 'localidade is required to update'}
        return flask.jsonify(response)

    # parameterized queries, good for security and performance
    statement = 'UPDATE dep SET local = %s WHERE ndep = %s'
    values = (payload['localidade'], ndep)

    try:
        res = cur.execute(statement, values)
        response = {'status': StatusCodes['success'], 'results': f'Updated: {cur.rowcount}'}

        # commit the transaction
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(error)
        response = {'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


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
