#!/bin/bash
COUNTRYLIST="bh br cn in it kh kr pe pk ru sg tw ua"
GEOBLOCKBASEDIR="/etc/geo-blocking"
if [ ! -d $GEOBLOCKBASEDIR ]; then
    mkdir $GEOBLOCKBASEDIR
fi
cd $GEOBLOCKBASEDIR
for i in $COUNTRYLIST; do
    echo  ----- creating ipset for country_$i
    # ipset destroy country_$i   # it can not do this while iptables is running.
    ipset flush country_$i       # flush it instead
    ipset -N country_$i hash:net
    wget -q -N http://www.ipdeny.com/ipblocks/data/countries/$i.zone
    for k in `cat $i.zone`; do
        ipset -A country_$i $k
    done
done
# Save the ipset rules for reboot
ipset save >/etc/sysconfig/ipset
# Reload iptables
if [ -e /etc/sysconfig/iptables ]; then
	iptables-restore < /etc/sysconfig/iptables
fi
