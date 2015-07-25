# pandora-box
Script to automatise Man In The Middle Attacks.

Features:

* Wireless-dongle power amplification.
* MAC address spoofing.
* Set-up of rogue access-point.
* Set-up of evil-twin attack 
	* Cloning an access-point 
	* De-authenticate its connected users to make them connect transparently 
	  to the evil-twin access-point.
* Real-time monitoring of the connected users on the fake/evil-twin access-point.
* Sniff and log the traffic.

## Requirements

This script is designed to run on the **Kali Linux** distribution.

## Usage

To run the pandora-box script, you first need to give it the execution right:
		
		$ chmod +x pandora-box
### Examples:
To launch the pandora-box script:

		$ ./pandora-box.sh
		
## Project information		
This script was developed as part of my master thesis work in June 2015.

