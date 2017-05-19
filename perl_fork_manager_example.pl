#!/usr/bin/perl

################################################################################
# Below is an example of code that uses Perl's Parallel::ForkManager for forking 
# out processes to run in parallel.
#
# I call RANDOM from bash instead of perl so that we get actual random numbers 
# and I call the sleep external to perl as well so I can monitor it in "ps" results.
# 
# At any time I only have up to 10 sleeps running.
#
# - Brad Allison
# Fri May 19 15:42:09 UTC 2017
################################################################################
 
use Parallel::ForkManager;
$pm = new Parallel::ForkManager(10);  #10 max

while () {
	# Forks and returns the pid for the child:
	my $pid = $pm->start and next; 

	# ... do some work in the child process ...
	forked_sub();
    
	$pm->finish; # Terminates the child process
  
}
$pm->wait_all_children;

sub forked_sub {
	# sleep (int(rand(5)) + 1);  # sleep 1-6 seconds
	# fork a system call instead, so we can see it in ps 
	$ran=`echo \$RANDOM % 10 + 1 | bc`;
	chomp $ran;
	print "sleeping $ran seconds \n";
	system("sleep $ran");
}
