#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'

if [ ! -f /usr/bin/apt ]; then
echo -e "${RED}Xivi only supports debian based systems.${RESET}" # how unfortunate
echo -e "${RED}Xivi: Installation Failed 😭${RESET}" # womp womp
exit
fi

echo -e "${BLUE}Xivi: Updating system and installing necessary packages... 📦${RESET}"
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

echo -e "${BLUE}Xivi: Deleting old project directory if it exists... 🔥${RESET}"
rm -rf ~/xivi-web-interface

echo -e "${BLUE}Xivi: Creating project directory... 📁${RESET}"
mkdir -p ~/xivi-web-interface
cp app.py ~/xivi-web-interface
cp schema.prisma ~/xivi-web-interface
cd ~/xivi-web-interface

#echo -e "${BLUE}Xivi: Creating and activating Python virtual environment... 🐍${RESET}"
#python3 -m venv venv
#source venv/bin/activate # Prisma does not work in a venv

echo -e "${BLUE}Xivi: Installing Python dependencies... 📚${RESET}"
pip3 install flask flask_httpauth requests docker cryptography prisma --break-system-packages # only because we can't use a venv

echo -e "${BLUE}Xivi: Initializing Prisma Database... 💾${RESET}"
prisma db push > /dev/null

cat << EOF > hash
$RANDOM$RANDOM$RANDOM$RANDOM
EOF

export API_KEY=$(sha512sum hash | awk '{print $1}')
rm -f hash

echo -e "${BLUE}Xivi: Setting API Key... 🔑${RESET}"
sed -i "s/api-key-here/$API_KEY/g" app.py

SERVER_IP=$(ip route get 1 | awk '{print $7;exit}')
echo -e "${GREEN}Xivi setup complete! 🎉${RESET}"
echo -e "To start the API, run the following command:"
echo -e "${YELLOW}cd ~/xivi-web-interface && source venv/bin/activate && python app.py${RESET}"
echo -e "The app will run on port 5000."
echo -e "${RED}Your API key is ${API_KEY}${RESET}"
echo -e "Access your Xivi application at: ${YELLOW}http://${SERVER_IP}:5000${RESET}"

#echo -e "${RED}Your API Key is: ${YELLOW}${API_KEY}${RESET}"
#echo -e "${RED}Keep this key safe and secure!${RESET}"
