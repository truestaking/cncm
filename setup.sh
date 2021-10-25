#!/bin/bash

REPO='https://raw.githubusercontent.com/truestaking/cncm/main'
DEST='/opt/cardano/cncm'

################################
#### CONVENIENCE FUNCTIONS #####
################################

get_input() {
  printf "$1: " >&2; read -r answer
  echo $answer
}

#Courtesy of cardano guild tools
get_answer() {
  printf "%s (y/n): " "$*" >&2; read -n1 -r answer
  while : 
  do
    case $answer in
    [Yy]*)
      return 0;;
    [Nn]*)
      return 1;;
    *) echo; printf "%s" "Please enter 'y' or 'n' to continue: " >&2; read -n1 -r answer
    esac
  done
}

generate_data(){
cat << EOF
{
"chain": "ada",
"name": "$NAME",
"telegram_username": "$TELEGRAM_USER",
"email_username": "$EMAIL_USER",
"monitor": {
  "process": "$MONITOR_PROCESS",
  "cpu": "$MONITOR_CPU",
  "nvme_heat": "$MONITOR_NVME_HEAT",
  "nvme_lifespan": "$MONITOR_NVME_LIFESPAN",
  "nvme_selftest": "$MONITOR_NVME_SELFTEST",
  "drive_space": "$MONITOR_DRIVE_SPACE",
  "oom_condition": "$MONITOR_OOM_CONDITION"
  }
}
EOF
}

write_env() {
  echo -ne "
##### CNCM user variables #####
### Uncomment the next line to set your own peak_load_avg value or leave it undefined to use the CNCM default
#peak_load_avg=

##### END CNCM user variables #####

#### DO NOT EDIT BELOW THIS LINE! #####
#### TO EDIT THESE VARIABLES, RUN update_monitor.sh ####
#### DO NOT COPY THIS FILE or edit the API KEY ####
API_KEY=$API_KEY
NAME='$NAME'
MONITOR_PROCESS=$MONITOR_PROCESS
MONITOR_CPU=$MONITOR_CPU
MONITOR_OOM_CONDITION=$MONITOR_OOM_CONDITION
MONITOR_DRIVE_SPACE=$MONITOR_DRIVE_SPACE
MONITOR_NVME_HEAT=$MONITOR_NVME_HEAT
MONITOR_NVME_LIFESPAN=$MONITOR_NVME_LIFESPAN
MONITOR_NVME_SELFTEST=$MONITOR_NVME_SELFTEST
EMAIL_USER=$EMAIL_USER
TELEGRAM_USER=$TELEGRAM_USER
ACTIVE=$ACTIVE
" | sudo dd of=$DEST/env
}

####################################
#### END CONVENIENCE FUNCTIONS #####
####################################

echo; echo
cat << "EOF"
   _____              _                     _   _           _                                                
  / ____|            | |                   | \ | |         | |                                               
 | |     __ _ _ __ __| | __ _ _ __   ___   |  \| | ___   __| | ___                                           
 | |    / _` | '__/ _` |/ _` | '_ \ / _ \  | . ` |/ _ \ / _` |/ _ \                                          
 | |___| (_| | | | (_| | (_| | | | | (_) | | |\  | (_) | (_| |  __/                                          
  \_____\__,_|_|  \__,_|\__,_|_| |_|\___/  |_|_\_|\___/ \__,_|\___|            _ _             _             
  / ____|                                    (_) |         |  \/  |           (_) |           (_)            
 | |     ___  _ __ ___  _ __ ___  _   _ _ __  _| |_ _   _  | \  / | ___  _ __  _| |_ ___  _ __ _ _ __   __ _ 
 | |    / _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | | | |\/| |/ _ \| '_ \| | __/ _ \| '__| | '_ \ / _` |
 | |___| (_) | | | | | | | | | | | |_| | | | | | |_| |_| | | |  | | (_) | | | | | || (_) | |  | | | | | (_| |
  \_____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, | |_|  |_|\___/|_| |_|_|\__\___/|_|  |_|_| |_|\__, |
                                                     __/ |                                              __/ |
                                                    |___/                                              |___/ 
EOF
echo; echo;
cat << "EOF"


 

Cardano Node Community Monitoring

Basic -> just the stuff you need near time alerting on

Simple -> just standard Linux command line tools

Essential -> everything you need, nothing more
    - node service status
    - out of memory error condition
    - loss of network connectivity
    - disk space
    - nvme heat, lifespan, and selftest
    - cpu load average

Free -> backend alerting contributed by True Staking

You will need:
    1.  your telegram user name or email address

EOF
echo;echo

if ! get_answer "Do you wish to install and configure CNCM?"; then exit; fi
echo; echo


##########################
#### SET ENV VARIABLES ####
##########################

#### Set active to be true by default in the setup.sh ####
ACTIVE=true

#### get name, default is hostname ###
NAME=$(hostname)
if get_answer "The default name is $NAME do you want to set a different name for this server account? "
then
  echo
  NAME=$(get_input "Please enter the name for this service account")
else echo
fi
echo

#### is the node process still running? ####
if get_answer "Do you want to be alerted if your node service stops running?"
    then 
	echo
        service=$(get_input "Please enter the service name you want to monitor? This is usually cnode")
        if (sudo systemctl -q is-active $service)
            then MONITOR_PROCESS=$service
            else
                MONITOR_PROCESS=false
                echo "\"systemctl is-active $service\" failed, please check service name and rerun setup."
                exit;exit
        fi
    else MONITOR_PROCESS=false
    echo
fi
echo

#### is there an out of memory error condition ####
if get_answer "Do you want to check for an out of memory error condition"
then MONITOR_OOM_CONDITION=true
else MONITOR_OOM_CONDITION=false
fi
echo; echo

#### is my CPU going nuts? ####
if get_answer "Do you want to be alerted if your CPU load average is high?"
    then MONITOR_CPU=true
        if ! sudo apt list --installed 2>/dev/null | grep -qi util-linux
            then sudo apt install util-linux
        fi
        if ! sudo apt list --installed 2>/dev/null | grep -qi ^bc\/
            then sudo apt install bc
        fi
    else MONITOR_CPU=false
fi
echo; echo

#### are the NVME drives running hot? ####
if get_answer "Do you want to be alerted for NVME drive high temperatures? "
    then MONITOR_NVME_HEAT=true
    else MONITOR_NVME_HEAT=false
fi
echo; echo

#### are the NVME drives approaching end of life? ####
if get_answer "Do you want to be alerted when NVME drives reach 80% anticipated lifespan?"
    then MONITOR_NVME_LIFESPAN=true
    else MONITOR_NVME_LIFESPAN=false
fi
echo; echo

#### are the NVME drives failing the selftest? ####
if get_answer "Do you want to be alerted when an NVME drives fails the self-assessment check? "
    then MONITOR_NVME_SELFTEST=true
    else MONITOR_NVME_SELFTEST=false
fi
echo; echo

#### are any of the disks at 90%+ capacity? ####
if get_answer "Do you want to be alerted when any drive reaches 90% capacity?"
    then MONITOR_DRIVE_SPACE=true
    else MONITOR_DRIVE_SPACE=false
fi
echo; echo

#### do we need to install NVME utilities? ####
if echo $MONITOR_NVME_HEAT,$MONITOR_NVME_LIFESPAN,$MONITOR_NVME_SELFTEST | grep -qi true
    then
        echo "checking for NVME utilities..."
        if ! sudo apt list --installed 2>/dev/null | grep -qi nvme-cli
            then
                echo "installing nvme-cli.."
                if ! sudo apt install nvme-cli
                then echo;
                    echo "CNCM setup failed to install nvme-cli. Please manually install nvme-cli and rerun setup."
                echo; echo
                fi
        fi
        if ! sudo apt list --installed 2>/dev/null | grep -qi smartmontools
            then
                echo "installing smartmontools..."
                if ! sudo apt install smartmontools
                then echo
                    echo "CNCM setup failed to install smartmontools. Please manually install nvme-cli and rerun setup."
                    echo; echo
                fi
        fi
	echo;
fi

#### alert via email? ####
if get_answer "Do you want to receive node alerts via email?" 
    then echo;
    EMAIL_USER=$(get_input "Please enter an email address for receiving alerts ")
    else EMAIL_USER=''
fi
echo

#### alert via TG ####
TELEGRAM_USER="";
if get_answer "Do you want to receive node alerts via Telegram?"
    then echo;
    TELEGRAM_USER=$(get_input "Please enter your telegram username ")
    echo "IMPORTANT: Please enter a telegram chat with our bot and message 'hi!' LINK: https://t.me/cardanocncm_bot"
    echo "IMPORTANT: Even if you have messaged our bot before, you must message him again"
    read -p "After you say "hi" to the cncm bot press <enter>."; echo
    else TELEGRAM_USER=''
fi
if ( echo $TELEGRAM_USER | grep -qi [A-Za-z0-9] ) 
    then echo -n "Please do not exit the chat with our telegram bot. If you do, you will not be able to receive alerts about your system. If you leave the chat please run update_monitor.sh"; echo ;
fi

#### check that there is at least one valid alerting mechanism ####
if ! ( [[ $EMAIL_USER =~ [\@] ]] || [[ $TELEGRAM_USER =~ [a-zA-Z0-9] ]] )
then
  logger "CNCM requires either email or telegram for alerting, bailing out of setup."  
  echo "CNCM requires either email or telegram for alerting. Rerun setup to provide email or telegram alerting. Bailing out."
  exit
fi

###############################
#### END SET ENV VARIABLES ####
###############################

#### register with truestaking alert server ####
API="$('/usr/bin/curl' -s -X POST -H 'Content-Type: application/json' -d "$(generate_data)" https://monitor.truestaking.com/register)"
if ! [[ $API =~ "OK" ]]
then
  logger "CNCM failed to obtain API KEY"
	echo
  echo $API
  echo
  exit
else
   API_KEY=$(echo $API | cut -f 2 -d  " " )
fi

sudo mkdir -p $DEST 2>&1 >/dev/null
write_env

echo
echo "installing cncm.service"
## curl cncm.service
sudo curl $REPO/cncm.service -O 
sudo mv ./cncm.service /etc/systemd/system/cncm.service
sudo systemctl enable cncm.service
echo "installing cncm.timer"
## curl cncm.timer
sudo curl $REPO/cncm.timer -O
sudo mv ./cncm.timer /etc/systemd/system/cncm.timer
## curl monitor.sh
sudo curl $REPO/monitor.sh -O
sudo mv ./monitor.sh $DEST/
sudo chmod +x $DEST/monitor.sh
## curl delete_account.sh
sudo curl $REPO/delete_account.sh -O
sudo mv ./delete_account.sh $DEST/
sudo chmod +x $DEST/delete_account.sh
## curl update_monitor.sh
sudo curl $REPO/update_monitor.sh -O
sudo mv ./update_monitor.sh $DEST/
sudo chmod +x $DEST/update_monitor.sh
echo
echo "Starting cncm service"
sudo systemctl enable cncm.timer
sudo systemctl start cncm.timer
echo
echo "You can update your preferences or stop monitoring and alerts at anytime by running update_monitor.sh"
echo ; echo
echo "you will get a summary of your configuration and registration shortly via email or TG."
echo; echo
echo "##########################################"
echo "In CNCM, every server has a unique API key."
echo "Here is the API key for this server: $API_KEY"
echo "You can also find it in $DEST/env"
echo "WARNING: you need this key to update or remove this account, so please store it safely!"
echo "##########################################"
