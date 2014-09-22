#!/bin/bash

##################################################
##########  BEGIN Plesk DV Functions #############
##################################################


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
function fcgierror(){
	#get the largest error_log
	errlog=$(find /var/www/vhosts/ -maxdepth 4 -type f -name error_log | xargs -rn1 du -h | sort -nr -k1 | head -1 | awk -F" " {'print $2'});
	logfilenum1=$(grep "mod_fcgid: can't apply process slot for" $errlog | wc -l);
	for i in {1..10}
	do
	clear;
	printf "\nThere are $(grep "mod_fcgid: can't apply process slot for" $errlog | wc -l) instances of \"mod_fcgid: can\'t apply process slot\" in $errlog\n\n";
	sleep 1;
	done
	printf "\nLargest error log: $(du -h $errlog)\n\n";
	logfilenum2=$(grep "mod_fcgid: can't apply process slot for" $errlog | wc -l);
	printf "In the last ten seconds, \"mod_fcgid: can't apply process slot for\" has occurred $(($logfilenum2-$logfilenum1)) time(s).\n\n";
	printf "The Following IP addresses have triggered this error:\n\n";
	printf " # | IP Address\n-------------------\n";
	grep "mod_fcgid: can't apply process slot for" $errlog | cut -d " " -f 8 | sed -s 's/]//' | sort -n | uniq -c | sort -nr | head -15 | column -t
	printf "\nHere are you current fcgid.conf settings:\n\n $(grep Fcgid /etc/httpd/conf.d/fcgid.conf | column -t)\n\n";

}

# BEGIN FUNCTION - Test PHP memory limit


# BEGIN FUNCTION - Check for DDoS attack


# BEGIN FUNCTION - Check database listing and the subsription it is tied to
function dbListing(){
	mysql -u admin -p$(cat /etc/psa/.psa.shadow) psa -e "select domains.name as Domain, data_bases.name as DB from domains, data_bases where data_bases.dom_id=domains.id order by domains.name;"
}

# BEGIN FUNCTION - See which log files are being access the most using lsof
function activeLogs(){
	# count how many processes have an access log open
	ps -C httpd | grep [:digit:] | head -1 | cut -d " " -f1 | lsof -i4 -c httpd | grep -P "(access|error)_(ssl_log)" | awk -F " " {'print $9'} | sort | uniq -c
}


##################################################
###########  END Plesk DV Functions ##############
##################################################




#CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC#
#########   BEGIN cPanel DV Functions  ###########
#CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC#


# BEGIN FUNCTION - 
function domList(){
	awk -F'=' '/^DNS/ {print $2}' /var/cpanel/users/*
}

# BEGIN FUNCTION - Check enabled repo lists
function repolist(){
	clear;
	#Output the enabled repos
	yum repolist enabled | grep -A15 "repo id"
}


#CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC#
#########  END cPanel DV Functions  ##############
#CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC#



#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
###########    BEGIN GRID FUNCTIONS    ###########
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#


# BEGIN FUNCTION - List domain names and their live DNS
function getGridDns(){
	echo -ne "$(dig @8.8.8.8 +short s$(echo $HOME | awk -F/ '{ print $3 }').gridserver.com) ";
	echo -ne "access domain:  "; 
	echo " ${SITE}.gridserver.com";
	echo -ne "$(dig @ns1.mediatemple.net +short $(whoami)) ";
	echo -ne "primary domain:      "; 
	echo $(whoami); 
	echo ""; ls -d ~/domains/*.* | awk -F"/" '{print $NF}' | while read DOMAIN; do DIG=$(dig +short @8.8.8.8 $DOMAIN);
	if [ "$DIG" != "" ];
		then echo $DIG $DOMAIN | column -t;
		fi;
		done
}


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
###########     END GRID FUNCTIONS     ###########
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#


# BEGIN FUNCTION - 

# BEGIN MENU
cat <<- _EOF_
What would you like to do?
1) Get stack info
2) Remove SSL Cert
3) Hostname/rDNS check
4) Sort logs by size
5) Check for FastCGI errors
6) 
_EOF_
read -p "Please enter your selection: " response;
