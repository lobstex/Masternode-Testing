#!/bin/bash

COIN_PATH='/usr/bin/'
COIN_TGZ='https://github.com/avymantech/lobstex/releases/download/v2.3/Lobstex.Linux.v2.3.zip'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')

#!/bin/bash
# Lobstex Update Script 
#
# Usage:
# bash Lobstex-update.sh 
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color



#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

echo -e "${YELLOW}Lobstex Update Script v1.0${NC}"

#KILL THE MFER
echo -e "${YELLOW}Killing deamon...${NC}"
function stop_daemon {
    if pgrep -x 'lobstexd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop lobstexd${NC}"
        lobstex-cli stop
        delay 30
        if pgrep -x 'lobstex' > /dev/null; then
            echo -e "${RED}lobstex daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            pkill lobstexd
            delay 30
            if pgrep -x 'lobstexd' > /dev/null; then
                echo -e "${RED}Can't stop lobstexd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}
#Function detect_ubuntu

 if [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
else
   echo -e "${RED}You are not running Ubuntu 16.04, Installation is cancelled.${NC}"
   exit 1

fi


#Delete .lobstexe contents 
echo -e "${YELLOW}Scrapping .lobstex...${NC}"
cd 
cd ~/.lobstex
rm -rf c* b* w* p* n* m* f* d* g*

#Delete OLD Binary
echo -e "${YELLOW}Deleting v1.3...${NC}"
cd ~
sudo rm -rf ~/lobstex
sudo rm -rf ~/usr/bin/lobstex*

# update packages and upgrade Ubuntu
echo -e "${YELLOW}Updating packages and Unbuntu...${NC}"
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev

sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev

sudo apt-get -y install libminiupnpc-dev

sudo apt-get -y install fail2ban
sudo service fail2ban restart

sudo apt-get install ufw -y
sudo add-apt-repository ppa:ubuntu-toolchain-r/test 
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install unzip

#Install new Binaries
echo -e "${YELLOW}Installing v1.0.1...${NC}"
cd ~
mkdir lobstex
cd lobstex
wget $COIN_TGZ
tar xzf $COIN_ZIP >/dev/null 2>&1 
rm -r $COIN_ZIP >/dev/null 2>&1

sudo cp ~/lobstex/lobstex* $COIN_PATH
sudo chmod 755 -R ~/lobstex
sudo chmod 755 /usr/bin/lobstex*

#Restarting Daemon
echo -e "${YELLOW}Restarting Daemon...${NC}"
    lobstexd -daemon
echo -ne '[##                 ] (15%)\r'
sleep 6
echo -ne '[######             ] (30%)\r'
sleep 6
echo -ne '[########           ] (45%)\r'
sleep 6
echo -ne '[##############     ] (72%)\r'
sleep 10
echo -ne '[###################] (100%)\r'
echo -ne '\n'

echo -e "${GREEN}Your masternode is now up to date${NC}"
echo ==========================================================
# EOF
