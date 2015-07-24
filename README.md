# pandora-box
A script to automatise man in the middle attacks.

Features:

		- Wireless-dongle power amplification.
		- MAC address spoofing.
		- Set-up of rogue access-point.
		- Set-up of evil-twin attack 
			- Cloning an access-point 
			- De-authenticate its connected users to make them connect 
			  transparently to the evil-twin access-point.
		- Real-time monitoring of the connected users on the fake/evil-twin access-point.
		- Sniff and log the traffic.
		
This script is optimized to run on Kali Linux (because it natively include all the required soft-wares).

## Usage

		$ chmod +x pandora-box
		$ ./pandora-box.sh


