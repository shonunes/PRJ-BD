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
from werkzeug.security import generate_password_hash, check_password_hash

app = flask.Flask(__name__)

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

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/register/patient - payload: {payload}')

    # validate every argument
    args = ['cc', 'username', 'password', 'health_number', 'emergency_contact', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'results': f'{arg} value not in payload'}
            return flask.jsonify(response)

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'CALL add_patient(%s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['health_number'], payload['emergency_contact'], payload['birthday'], payload['email'],)

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

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/register/assistant - payload: {payload}')

    # validate every argument
    args = ['cc', 'username', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'results': f'{arg} value not in payload'}
            return flask.jsonify(response)

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'CALL add_assistant(%s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'],)

    try:
        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['cc']}

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

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/register/nurse - payload: {payload}')

    # validate every argument
    args = ['cc', 'username', 'password', 'contract_id', 'salary', 'contract_issue_date', 'contract_due_date', 'birthday', 'email', 'cc_superior']
    for arg in args:
        if arg not in payload:
            response = {'status': StatusCodes['api_error'], 'results': f'{arg} value not in payload'}
            return flask.jsonify(response)

    # generate password hash to store in the database
    hashed_password = generate_password_hash(payload['password'], method='sha256')

    # parameterized queries, good for security and performance
    statement = 'CALL add_nurse(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
    values = (payload['cc'], payload['username'], hashed_password, payload['contract_id'], payload['salary'], payload['contract_issue_date'], payload['contract_due_date'], payload['birthday'], payload['email'], payload['cc_superior'],)

    try:
        cur.execute(statement, values)

        # commit the transaction
        conn.commit()
        response = {'status': StatusCodes['success'], 'results': payload['cc']}

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
## PUT
##
## User login
##
## To use it, access:
## 
## http://localhost:8080/dbproj/user
##
@app.route('/dbproj/user', methods=['PUT'])
def login():
    auth = flask.request.autorization

    if auth and auth.password == 'password':
        token = jwt.encode({'user': auth.username, 'exp': time.time() + 60 * 60}, app.config['SECRET_KEY'])
        return flask.jsonify({'token': token.decode('UTF-8')})
    return flask.Flask.make_response('Could not verify!', 401, {'WWW-Authenticate': 'Basic realm="Login Required"'})















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
