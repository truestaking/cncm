# Cardano Node Community Monitoring
brought to you by [True Staking](https://truestaking.com)

## What is it?

Just basic Linux server monitoring. Sometimes, the simplest solution is the best solution. For all the trends, graphs, metrics, statistics you might need, there is Prometheus. For knowing your server has no issues, there is CNCM.

Server checks include:
- node service status
- out of memory error condition
- loss of network connectivity
- disk space
- nvme heat, lifespan, and selftest
- cpu load average

## How does it work?

Running the installer (setup.sh) generates an api key unique to your server, and creates a service (cncm.service) triggered every 2 minutes by cncm.timer. You select what you want to monitor, and the checks are run every 2 minutes. At the beginning of each check series, an "I'm alive" message is sent (https via curl) to our backend server. In the (hopefully) rare event that an alert is generated, an additional outbound https call via curl to monitor.truestaking.com submits the alert, and the backend forwards the alert to you via telegram or email.

Note: If our backend server doesn't receive an "I'm alive" message from your node within 5 minutes, then it sends the "Is Alive Error" alert.

Each server should have a unqiue api key. Run the installer (setup.sh) on each server you want to have monitoring on. 

Monitoring preferences can be update and monitoring can be paused using update_monitor.sh. A server account can be deleted and all monitoring stopped using delete_account.sh.

Feedback is welcome, and we hope this benefits the Cardano Node Community!

## Install 

To install, run:
```
curl https://raw.githubusercontent.com/truestaking/cncm/main/setup.sh -O;
chmod +x ./setup.sh;
./setup.sh;
```

Installing creates the folder structure:
```
/opt/cardano/cncm        # Top level folder
...
- env                     # Environment variables
- monitor.sh              # Monitor script ran every 2 minutes by cncm.service, triggered by cncm.timer
- update_monitor.sh       # Update script used to start/stop monitoring and change local and remote variables 
- delete_account.sh       # Remove a server account (requires server API key)
```

Tested on Ubuntu 20.04
