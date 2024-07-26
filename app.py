from flask import Flask, request, jsonify
from flask_httpauth import HTTPTokenAuth
import logging
import docker
from prisma import Prisma
import random
# removed unnesessary imports holy crap what is my spelling
app = Flask(__name__)
auth = HTTPTokenAuth(scheme='Bearer')

API_KEY = "api-key-here" # this is sedded out and replaced with the api key at install time
tokens = {API_KEY: "user"}

@auth.verify_token
def verify_token(token):
    if token in tokens:
        return tokens[token]
    return None

#def generate_instance_id():
#    return ''.join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(8)) # just use container ids smh

@app.route('/')
def index():
    return 'Xivi API is running! 🎉'

@app.route('/start', methods=['POST'])
@auth.login_required
async def start_instance():
    try:
        db = Prisma()
        await db.connect()
        client = docker.from_env()
        novnc = random.randint(49153, 65560)
        vnc = random.randint(49153, 65550)
        while vnc == novnc:
            novnc = random.randint(49153, 65560)
        c = client.containers.run("newprixmix", ports={6080:novnc, 5901:vnc}, detach=True, mem_limit="1024m", oom_kill_disable=True) # replace with actual xivi container image name
        await db.container.create({
            'id':c.id,
            'name':c.name
        }) # add an "expires" value if you want to impose session limits
        # for users, i can't do anything because it's in the frontend
        return jsonify({
            "message": f"Xivi instance started 🚀",
            "id": c.id,
            "name":c.name,
            "novnc_port": novnc
        }), 200
    except Exception as e:
        logging.exception("An error occurred 😱")
        return jsonify({"error": str(e)}), 500

@app.route('/delete', methods=['POST'])
@auth.login_required
async def delete_instance():
    instance_id = request.json.get('id')
    if not instance_id:
        return jsonify({"error": "Container ID is required"}), 400

    try:
        db = Prisma()
        await db.connect()
        client = docker.from_env()
        c = client.containers.get(instance_id)
        c.kill()
        await db.container.delete(where={"id":instance_id})
        return jsonify({"message": "Container deleted successfully"}), 200 # no emoji?
    except Exception as e:
        logging.exception("An error occurred 😱")
        return jsonify({"error": str(e)}), 500

@app.route('/list', methods=['GET'])
@auth.login_required
async def list_instances():
    db = Prisma()
    await db.connect()
    found = await db.container.find_many(where={'name'})
    return jsonify({"instances": json.dumps(found)}), 200 # improve this later please (make Container class json serializable) # its prisma now so nvm
    #############################
    ### for better container management, store containers in a prisma db
    #############################
    # welp i did that
if __name__ == '__main__':
    print("App running on port: 5000 🎉")
    app.run(host='0.0.0.0', port=5000, debug=True)
