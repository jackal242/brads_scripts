#!/usr/bin/perl
#
# Script to find and return the stack trace for a what's causing the lock
#

use File::Basename qw/basename/;
use strict;

my $debug =1 ;
my %lock_count ;
my $progname = basename $0 ;
my $default_thread_dump = ();
if (-d "/usr/local/tomcat/default/logs") {
	`ls -t /usr/local/tomcat/default/logs |grep thread | head -1`; # default log file is most recent thread dump
}
my $thread_dump = defined $ARGV[0] && length $ARGV[0] > 0 ? $ARGV[0] : $default_thread_dump;


sub usage {
	print "\nUSAGE:\n";
	print "$progname <thread_dump_file>\n";
	print "\n";
}

if ($thread_dump eq '') {
	print "\nERROR: log file not provided\n";
	usage();
	exit ;
}

unless (-e $thread_dump) {
	print "\nERROR: $thread_dump does not exist!\n";
	usage();
	exit ;
}

# Print message
print "Log_File:\t$thread_dump \n" if ($debug) ;

# Get the thread count
#my $thread_count =`grep TP-Proc $thread_dump | wc -l` ;
my $thread_count =`egrep '.*prio.*tid.*nid' $thread_dump | wc -l` ;
#my $thread_count =`egrep "prio=.*tid=.*nid=.*" $thread_dump | wc -l` ;
chomp ($thread_count);
print "Total_Threads:\t$thread_count\n";

# Read the file
open FILE, "<", "$thread_dump" or die $! ;
my @lines = <FILE>;
close FILE;

# First time through the file: Get the counts of locks
	
my $lock ;
foreach my $line (@lines) {
	chomp $line ;
	$lock = () ;
	if ( $line =~ /waiting to lock <(.*)>/ ) {
		$lock = $1 ;
		# print "$lock : ";
		$lock_count{$lock} = $lock_count{$lock} + 1 ;
		# print " -- $lock_count{$lock} \n";
	}
}

my $offending_lock;
foreach $lock (sort {$lock_count{$b} cmp $lock_count{$a}} keys %lock_count) {
	$offending_lock = $lock;
	print "Lock_ID:\t$offending_lock happened $lock_count{$lock} times\n";
	last ; # only return the highest value which is the first one in the sort
}

# Second time through the file: Get the stack trace stanza
my @stack_trace=();
my $matched = 0 ;
foreach my $line (@lines) {
	if ($line =~ /prio=.*tid=.*nid=.*/) {
		if ($matched == 1 ) {
			last; # quit going, we found the stack trace stanza we are looking for
		} 
		@stack_trace=(); #start of new stack trace stanza, reset the stack_trace
	}
	push (@stack_trace, $line);
	push (@stack_trace,"\n");
	if ($line =~ /locked <$offending_lock/) {
		# Matched the lock in this stack trace stanza
		$matched = 1 ;
	}
}
# Return the stack trace stanza
print "====================\n\n";
foreach my $line (@stack_trace) {
	print $line;
}

