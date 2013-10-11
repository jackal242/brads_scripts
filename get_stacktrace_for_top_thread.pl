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
my $top_intervals=3 ;

#################################################################
# Usage
#################################################################
sub usage {
	print "\nUSAGE:\n";
	print "$progname\n";
	print "\n";
}

#################################################################
# Get the top thread for tomcat
#################################################################
$cmd="top -H -n $top_intervals -b |grep tomcat | grep java | sort -rn -k 9 | head -10" ;
print "Running: $cmd \n" if ($debug) ;
$lwp_id=`$cmd`;
print $lwp_id if ($debug);
chomp($lwp_id);
if ($lwp_id =~ /([0-9]+).*tomcat.*/) {
   $lwp_id = $1 ;
} else {
   print "no lwp id found\n";
   exit 1;
}
print "====================\n" if ($debug);
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
print "====================\n\n";
foreach my $line (@stack_trace) {
   print $line;
}

