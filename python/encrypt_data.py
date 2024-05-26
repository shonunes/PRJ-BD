from cryptography.fernet import Fernet
import json
import os

def generate_key(file_path="secret.key"):
    key = Fernet.generate_key()
    with open(file_path, "wb") as key_file:
        key_file.write(key)

def load_key(file_path="secret.key"):
    return open(file_path, "rb").read()

def encrypt_file(key, file_path="config.json"):
    cipher = Fernet(key)

    with open(file_path, "r") as json_file:
        config_data = json.load(json_file)

    config_json = json.dumps(config_data)
    encrypted_data = cipher.encrypt(config_json.encode())

    with open("config.enc", "wb") as enc_file:
        enc_file.write(encrypted_data)

    os.remove(file_path)


if __name__ == "__main__":
    generate_key()

    key = load_key()

    encrypt_file(key)
