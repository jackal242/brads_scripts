#!/usr/bin/perl
#################################################################
#
# Perl script for grabbing full tomcat thead dump
#
# Author: Brad Allison
# Date: Thu Oct 10 13:25:03 EDT 2013
#
#################################################################
use strict;
use File::Basename qw/basename/;
use File::Tail;
# use Getopt::Long;

$| =1 ;

 
#################################################################
# My's
#################################################################
my $debug =1 ;
my $progname = basename $0 ;
my $parent_pid=();
my $tomcat_log_file="/usr/local/tomcat/default/logs/catalina.out";
my @thread_dump_data=();
my $file;
my $line;
my @stack_trace=();
my $cmd ;
my $samples;
my $top_intervals=3 ;
my $result;
my $count;
my @cmd_out ;
my $help;
my $lwp;


#################################################################
# Get PID for lwp_id
#################################################################
#$cmd="ps -eL |grep $lwp_id" ;
$cmd=" ps -utomcat -opid,cmd |grep java ";
print "Running: $cmd \n" if ($debug) ;
$parent_pid=`$cmd`;
chomp($parent_pid);
if ($parent_pid =~ /([0-9]+).*\//) {
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
# Return the stack trace stanza
#################################################################
foreach my $line (@thread_dump_data) {
  	print $line;
}

