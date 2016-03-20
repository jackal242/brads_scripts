#!/bin/bash
MAX_SLEEPS=10		# Max number of sleeps allowed
sleepcount=0		# total count of spawned sleeps

spawn_a_sleep_process () {
	# this is the function that i want to run in parallel.
	# sleep 1 to 20 seconds randomly
 	sleep $[ ( $RANDOM % 20 )  + 1 ]s  
}

	
get_count_of_sleeps_running () {
	sleeps_running=0	# total currently running sleeps
	for pid in ${pids[*]}; do 
		# echo "checking pids $pid"
		if kill -0 $pid > /dev/null 2>&1; then
			# echo "PID=$pid is running."
			let "sleeps_running++"  # increment count
		fi
	done
	
}
	        
for i in {0..50};do
	echo $i
		
	get_count_of_sleeps_running ; # Update the count
	# echo SLEEPS RUNNING = $sleeps_running 
	while [[ "$sleeps_running" -ge "$MAX_SLEEPS" ]]; do
		# echo "WAITING NOW.  sleeps running=$sleeps_running"
		get_count_of_sleeps_running ; # Update the count
	done
	let "sleepcount++"  # increment count
	spawn_a_sleep_process  &  # this is the function i want to run parallel
	pids[${sleepcount}]=$!;
	# echo "Sleep Count = $sleepcount"
done

exit 0;
