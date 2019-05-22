#!/bin/bash
# Lobstex Masternode Setup Script for Ubuntu 16.04 LTS
# 
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash lobstex-setup.sh [Masternode_Private_Key]
#
# Example 1: Existing genkey created earlier is supplied
# bash lobstex-setup.sh 27dSmwq9CabKjo2L3UD1HvgBP3ygbn8HdNmFiGFoVbN1STcsypy
#
# Example 2: Script will generate a new genkey automatically
# bash lobstex-setup.sh
#
#Color codes

RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#lobstex TCP port
PORT=14146

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }
#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }
#Stop daemon if it's already running

function stop_daemon {
    if pgrep -x 'lobstexd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop lobstexd${NC}"
        lobstex-cli stop
        delay 30
        if pgrep -x 'lobstexd' > /dev/null; then
            echo -e "${RED}lobstexd daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill lobstexd
            delay 30
            if pgrep -x 'lobstexd' > /dev/null; then
                echo -e "${RED}Can't stop lobstexd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear
echo -e "${YELLOW}lobstex Masternode Setup Script for Ubuntu 16.04 LTS${NC}"
echo -e "${GREEN}Updating system and installing required packages...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi

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


#Generating Random Password for JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${YELLOW}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#Installing Daemon
echo -e "${GREEN}Installing Daemon....${NC}"
wget https://github.com/avymantech/lobstex/releases/download/v2.3/Lobstex.Linux.v2.3.zip
unzip Lobstex.Linux.v2.3.zip
chmod u+x lobstexd
chmod u+x lobstex-cli
./lobstexd -daemon
sleep 5


#Create datadir
if [ ! -f ~/.lobstex/lobstex.conf ]; then 
	sudo mkdir ~/.lobstex
fi

echo -e "${YELLOW}Creating lobstex.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.lobstex/lobstex.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.lobstex/lobstex.conf

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(./lobstex-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR:${YELLOW}Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create lobstex.conf
    echo -e "${YELLOW}Stopping daemon to create lobstex.conf....${NC}"
    ./lobstex-cli stop
    echo -ne '[##                 ] (15%)\r'
    sleep 6
    echo -ne '[######             ] (30%)\r'
    sleep 9
    echo -ne '[########           ] (45%)\r'
    sleep 6
    echo -ne '[##############     ] (72%)\r'
    sleep 10
    echo -ne '[###################] (100%)\r'
    echo -ne '\n'
    sudo ufw allow 14146
fi

# Create lobstex.conf
echo -e "${YELLOW}Creating lobstex.conf....${NC}"
cat <<EOF > ~/.lobstex/lobstex.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
masternode=1
maxconnections=256
longtimestamps=1
externalip=$publicip
masternode=1
bind=$publicip:$PORT
bind=0.0.0.0:$PORT
masternodeaddr=$publicip:$PORT
port=$PORT
masternodeprivkey=$genkey

addnode=45.32.130.61
addnode=51.75.69.79
addnode=138.197.66.117
addnode=217.61.0.190
addnode=45.63.115.26
addnode=51.158.79.70
addnode=108.61.123.203
addnode=167.99.203.221
addnode=47.92.123.3


EOF

#Finally, starting lobstex daemon with new lobstex.conf
echo -e "${GREEN}Finally, starting lobstex daemon with new lobstex.conf....${NC}"
./lobstexd -daemon
delay 5


echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$publicip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your 10,000 lobs collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the lobstex network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}mn1${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!
Currently your masternode is syncing with the lobstex network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in lobstex.conf:
${YELLOW}cat ~/.lobstex/lobstex.conf${NC}
Here is your lobstex.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.lobstex/lobstex.conf
echo -e "
${NC}-------------------------------------------------
NOTE: To edit lobstex.conf, first stop the lobstexd daemon,
then edit the lobstex.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the lobstexd daemon back up:
to stop:   ${YELLOW}./lobstex-cli stop${NC}
to edit:   ${YELLOW}nano ~/.lobstex/lobstex.conf${NC}
to start:  ${YELLOW}./lobstexd${NC}
========================================================================
To view lobstexd debug log showing all MN network activity in realtime:
${YELLOW}tail -f ~/.lobstex/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
${YELLOW}stop${NC}"

clear_stdin
#
