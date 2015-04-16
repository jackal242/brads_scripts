#!/bin/bash
#######################################################
#  Get the IOPS of an AWS Volume 
#
# Author: Brad Allison
# Date: Thu Apr 16 17:41:01 UTC 2015
#######################################################


#######################################################
# Check passed option
#######################################################
VOLUME=$1
if [ -z "`echo $VOLUME | egrep -o 'vol-........'`" ]; then
	echo "Usage: $0 vol-abcd1234"
fi

#######################################################
# Determine Region
#######################################################
REGIONS="us-east-1 us-west-1 us-west-2"
for x in $REGIONS; do
	if aws ec2 describe-volume-status --region $x --volume-ids $VOLUME > /dev/null 2>&1 ; then
		VOL_REGION=$x
		break
	fi
done
if [ -z $VOL_REGION ]; then
	echo $VOLUME not found in any defined regions.  Exiting....
	exit
fi

#######################################################
# Get CloudWatch Data
#######################################################
export PERIOD=3600; 
WRITEOPS="$(aws cloudwatch get-metric-statistics --metric-name VolumeWriteOps --start-time `date -d '1 hour ago' "+%Y-%m-%dT%H:%M:%S"` --end-time `date "+%Y-%m-%dT%H:%M:%S"` --period $PERIOD --namespace AWS/EBS --statistics Sum --dimensions Name=VolumeId,Value=${VOLUME} --region $VOL_REGION | grep Sum | egrep -o [0-9.]* | awk -v PERIOD=$PERIOD {'print $1/PERIOD'})"
READOPS="$(aws cloudwatch get-metric-statistics --metric-name VolumeReadOps --start-time `date -d '1 hour ago' "+%Y-%m-%dT%H:%M:%S"` --end-time `date "+%Y-%m-%dT%H:%M:%S"` --period $PERIOD --namespace AWS/EBS --statistics Sum --dimensions Name=VolumeId,Value=${VOLUME} --region $VOL_REGION | grep Sum | egrep -o [0-9.]* | awk -v PERIOD=$PERIOD {'print $1/PERIOD'})"


#######################################################
# Return The SUM of the Write and Read
#######################################################
echo "$WRITEOPS+$READOPS" | bc 


