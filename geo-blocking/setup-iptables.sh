#!/bin/bash
COUNTRYLIST="bh br cn in it kh kr pe pk ru sg tw ua"

# Save the current iptables just in case
iptables-save > /etc/sysconfig/iptables.bk.`date +%s%3N`
	
# Flush any current rules in memory
echo  Flushing current iptables rules
iptables -F

# Loop through the countries
for i in $COUNTRYLIST; do
    
	echo  ----- creating iptables rules for country_$i
	iptables -A INPUT -m set --match-set country_$i src -j LOG --log-prefix "iptables: DROP domain=$i: " --log-level 6
	iptables -A INPUT -m set --match-set country_$i src -j DROP

done

# Save iptables
iptables-save > /etc/sysconfig/iptables

