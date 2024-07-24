#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${BLUE}Xivi: Updating system and installing necessary packages... 📦${RESET}"
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

echo -e "${BLUE}Xivi: Deleting old project directory if it exists... 🔥${RESET}"
rm -rf ~/xivi-web-interface

echo -e "${BLUE}Xivi: Creating project directory... 📁${RESET}"
mkdir -p ~/xivi-web-interface
cd ~/xivi-web-interface

echo -e "${BLUE}Xivi: Creating and activating Python virtual environment... 🐍${RESET}"
python3 -m venv venv
source venv/bin/activate

echo -e "${BLUE}Xivi: Installing Python dependencies... 📚${RESET}"
pip install flask flask_httpauth requests

API_KEY=$(openssl rand -hex 32)

echo -e "${BLUE}Xivi: Creating Python script... 🐍${RESET}"
cat << EOF > app.py
from flask import Flask, request, jsonify
from flask_httpauth import HTTPTokenAuth
import logging
import requests
import secrets
import string
import os

app = Flask(__name__)
auth = HTTPTokenAuth(scheme='Bearer')

API_KEY = os.getenv('API_KEY', '${API_KEY}')
tokens = {API_KEY: "user"}

@auth.verify_token
def verify_token(token):
    if token in tokens:
        return tokens[token]
    return None

def generate_instance_id():
    return ''.join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(8))

@app.route('/')
def index():
    return 'Xivi API is running! 🎉'

@app.route('/start', methods=['POST'])
@auth.login_required
def start_instance():
    try:
        instance_id = generate_instance_id()
        return jsonify({
            "message": f"Xivi instance started 🚀",
            "id": instance_id
        }), 200
    except Exception as e:
        logging.exception("An error occurred 😱")
        return jsonify({"error": str(e)}), 500

@app.route('/delete', methods=['POST'])
@auth.login_required
def delete_instance():
    instance_id = request.json.get('id')
    if not instance_id:
        return jsonify({"error": "Instance ID is required"}), 400
    
    try:
        return jsonify({"message": "Instance deleted successfully"}), 200
    except Exception as e:
        logging.exception("An error occurred 😱")
        return jsonify({"error": str(e)}), 500

@app.route('/list', methods=['GET'])
@auth.login_required
def list_instances():
    return jsonify({"instances": []}), 200

if __name__ == '__main__':
    print(f"API Key: {API_KEY}")
    print("App running on port: 5000 🎉")
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

SERVER_IP=$(ip route get 1 | awk '{print $7;exit}')

echo -e "${GREEN}Xivi setup complete! 🎉${RESET}"
echo -e "To start the API, run the following command:"
echo -e "${YELLOW}cd ~/xivi-web-interface && source venv/bin/activate && python app.py${RESET}"
echo -e "The app will run on port 5000."
echo -e "Access your Xivi application at: ${YELLOW}http://${SERVER_IP}:5000${RESET}"

echo -e "${RED}Your API Key is: ${YELLOW}${API_KEY}${RESET}"
echo -e "${RED}Keep this key safe and secure!${RESET}"
