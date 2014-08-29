#!/bin/bash

# BEGIN FUNCTION - Check overall server status
function getversions(){
	clear; 
	echo -e "kernel version: $(uname -r)" ; 
	cat /etc/*release | uniq; 
	echo; 
	rpm -q psa ; 
	cat /usr/local/psa/version; 
	cat /usr/local/psa/core.version ; 
	mysql -u admin -p$(cat /etc/psa/.psa.shadow) psa -e "select * from misc where param = 'version' \G;"; 
	cat /root/.autoinstaller/microupdates.xml; 
	grep -i installed $_ ; 
	echo; 
	mysql -V; 
	echo; 
	php -v;
}

# BEGIN FUNCTION - Get info about the system
#function getstats(){
	#GET meminfo from the proc directory
	#while read line; do num=$(echo $line | awk -F" " {'print $2'}); echo $((${num}/1024)); done < /proc/meminfo
#}

# BEGIN FUNCTION - Disassociate SSL from domain
function rmssl(){
	clear;
	# get id for usage
	mysql -u'admin' -p`cat /etc/psa/.psa.shadow` psa -e"SELECT domains.id,domains.name FROM domains JOIN hosting ON hosting.dom_id=domains.id;"

	#this array will be used to validate input
	idx=($(mysql -u'admin' -p`cat /etc/psa/.psa.shadow` psa -e"SELECT domains.id,domains.name FROM domains JOIN hosting ON hosting.dom_id=domains.id \G;" | grep 'id:' | awk {'print $2'}));
	# check user input
	L=true
	while [ "$L" == true ]; do
		read -p "Enter the ID for the domain who's SSL you want to remove: " idn;

		    for i in ${idx[@]}; do
				if [ "$idn" == "${i}" ]; then
					L=false;
					break;
				fi
			done
		if [ ${L} == true ]; then
			printf "\n\nThat is not a valid domain ID. Please try again.\n\n";
		fi
	done

	# unlink the certificate from the
	mysql -u'admin' -p`cat /etc/psa/.psa.shadow` psa -e"update hosting set certificate_id=0 where dom_id=${idn};"
	read -t 1 -p "Target annihilated."
	clear;
}

# BEGIN FUNCTION - Check hostname for server, postfix, and compare to PTR record
function checkhost(){
	clear;
	printf "\nYour hostname is $(hostname -f)\n\n";
	hostset=$(grep "HOSTNAME" /etc/sysconfig/network | cut -d '"' -f 2);
	printf "Your hosts file has the following entry for your domain name: $(grep $hostset /etc/hosts)\n\n";
	myip=$(dig @resolver1.opendns.com myip.opendns.com | grep ^myip.opendns.com | tr '\t' : | cut -d: -f5);
	printf "Reverse DNS for IP $myip returns hostname $(dig +short -x $myip)\n\n";
								
}

# BEGIN FUNCTION - Check for largest log files
function logsort(){
	clear;
	#This will output *_log files in sorted order of size from highest to lowest
	find /var/www/vhosts/ -maxdepth 4 -type f -name "*_log" | xargs ls -l | awk {'print $5," ----- " , $9'} | sort -nrk1 | head -10;
}

# BEGIN FUNCTION - Check error logs for mod_fcgid errors


# BEGIN FUNCTION - Test PHP memory limit


# BEGIN FUNCTION - Check for DDoS attack


# BEGIN FUNCTION - check enabled repo lists
function repolist(){
	clear;
	#Output the enabled repos
	yum repolist enabled | grep -A15 "repo id"
}


rmssl
