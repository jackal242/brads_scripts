#!/usr/bin/perl
#################################################################
#
# Perl script for grabbing the stack trace of the tomcat thread
# using the most CPU on the host
#
# Author: Brad Allison
# Date: Thu Oct 10 13:25:03 EDT 2013
#
#################################################################
use strict;
use File::Basename qw/basename/;
use File::Tail;
use Getopt::Long;

$| =1 ;

 
#################################################################
# My's
#################################################################
my $debug =1 ;
my $progname = basename $0 ;
my $lwp_id = ();
my $parent_pid=();
my $tomcat_log_file="/usr/local/tomcat/default/logs/catalina.out";
my @thread_dump_data=();
my $file;
my $line;
my $lwp;
my @stack_trace=();
my $cmd ;
my $samples;
my $top_intervals=3 ;
my $result;
my $count;
my @cmd_out ;
my @lwp_list;
my $count_lwp_list;
my $help;

#################################################################
# Usage
#################################################################
sub usage {
	print "\nUSAGE:\n";
	print "$progname\n";
	print "$progname --count ## --samples ## \n";
	print "\n";
	print "Count is the number of threads stracktraces to return\n";
	print "Samples is the number of 'top' samples to run\n";
	print "\n";
}

##########################################
## Get Passed in options
###########################################
$result = GetOptions ( 
	"help"       => \$help, #flag
	"count=s"    => \$count, #string
	"samples=s"  => \$samples); # string
if ($help){
	usage();
	exit;
}
if (! $count) {
	$count =1 ;  # Return at least 1 stacktrace for the top thread.
} else {
	print "COUNT = $count\n" if ($debug);
}
if (! $samples) {
	$samples=$top_intervals;
} else {
	print "TOP SAMPLE SIZE = $samples\n";
}

#################################################################
# Get the top thread for tomcat
#################################################################
$cmd="top -H -n $samples -b |grep tomcat | grep java | sort -rn -k 9 | head -10" ;
print "Running: $cmd \n" if ($debug) ;
@cmd_out=`$cmd`;
foreach my $line (@cmd_out) {
	print $line ;
	$count_lwp_list=@lwp_list;
	next if ($count_lwp_list >= $count);
	if ($line =~ /([0-9]+).*tomcat.*/) {
		if ( grep {$_ eq $1} @lwp_list) {
			#print "$1 is already in the lwp_list \n";
		} else {
			#print "Adding $1 to lwp_list\n";
			push (@lwp_list, $1) ;
		}
	}
}
foreach $lwp_id (@lwp_list) {
	print "LWP_ID=$lwp_id\n" if ($debug);
	chomp($lwp_id);
}
print "====================\n" if ($debug);
$lwp_id=$lwp_list[0];
print "Top Tomcat LWP Id = $lwp_id\n";

#################################################################
# Exit if we can't get a lwp id
#################################################################
if ($lwp_id eq ''){
	print "\nERROR: no lwp id provided\n";
	usage();
	exit ;
}

#################################################################
# Get PID for lwp_id
#################################################################
$cmd="ps -eL |grep $lwp_id" ;
print "Running: $cmd \n" if ($debug) ;
$parent_pid=`$cmd`;
chomp($parent_pid);
if ($parent_pid =~ /([0-9]+).*$lwp_id.*/) {
	$parent_pid = $1 ;
} else {
	print "no parent_pid found\n";
	exit 1;
}
print "Parent PID = $parent_pid\n";



#################################################################
# Call thread dump
#
# If you send tomcat a kill -3 signal it will cause tomcat to 
# write out a thread dump to it's log file, which I capture and 
# parse.
#################################################################
my $pid= fork() // die "Can't fork : $!" ;
if ($pid == 0) {
	print "Child proces started\n" if ($debug);
	$cmd="sleep 5; kill -3 $parent_pid";
	system($cmd);
	exit;
}
$file=File::Tail->new(name=>$tomcat_log_file, interval=>3);
while (defined($line=$file->read)) {
	last if ($line =~ /^Heap/) ;
	if ($line =~ /nid=(0x[[:xdigit:]]+)/) {
		$lwp = hex($1);
		$line =~ s/nid=/lwp=$lwp nid=/;
	}
	push (@thread_dump_data,$line);
}

#################################################################
# Parse the thread dump looking for our single stack trace
#################################################################
foreach $lwp_id (@lwp_list) {
	print "============================================\n";
	print " LWP_ID = $lwp_id\n";
	print "============================================\n";
	my $matched=0;
	foreach $line (@thread_dump_data) {
   	    if ($line =~ /prio=.*tid=.*lwp=.*nid=.*/) {
      	        if ($matched == 1 ) {
         	    last; # quit going, we found the stack trace stanza we are looking for
      	        }
      	        @stack_trace=(); #start of new stack trace stanza, reset the stack_trace
   	    }
   	    push (@stack_trace, $line);
   	    if ($line =~ /lwp=$lwp_id/) {
      	        # Matched the lwp_id in this stack trace stanza
      	        $matched = 1 ;
   	    }
	}

	#################################################################
	# Return the stack trace stanza
	#################################################################
	foreach my $line (@stack_trace) {
   	    print $line;
	}
}
