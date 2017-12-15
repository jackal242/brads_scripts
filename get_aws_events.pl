#!/usr/bin/perl
####################################################################################################################
# Script to get all outstanding AWS Events (reboots/maintenance events) for all your instances.
#
# Includes a --nagios mode for running as a nagios plugin.
#
# Author: Brad Allison
# Date: Sun Aug 16 18:45:08 EDT 2015
#
####################################################################################################################
use strict ;
use Getopt::Long;
use Data::Dumper;
use JSON ;
use strict;

###########################
# My's
###########################
my $tmp_instance_id;
my $tmp_instance_name;
my $tmp_code;
my $tmp_date;
my $tmp_description;
my $json = JSON->new->allow_nonref;
my %instance_name_hash;
my %event_date_hash;
my %event_code_hash;
my %event_description_hash;
my $nagios;
my $result;
my $count;
my $debug;

##########################################
# Get Passed in options
##########################################
$result = GetOptions (
        "nagios"    => \$nagios, # Flag to enable nagios check mode
        "debug"     => \$debug,  # debug flag
);


###########################
# Main
###########################
get_event_data("us-east-1");
get_event_data("us-west-1");
get_event_data("us-west-2");
get_aws_name_hash("us-east-1");
get_aws_name_hash("us-west-1");
get_aws_name_hash("us-west-2");
print_results();
exit_code_for_nagios() if ($nagios) ;

###########################
# Sub To get event data
###########################
sub get_event_data {
	my $region=shift;
	my $cmd="aws ec2 describe-instance-status --region $region --filter Name=event.description,Values=* --query '{EventStatus:InstanceStatuses[].{Event:[{InstanceId:InstanceId},{EventDetails:Events[]}]}}' --output json";
	print "About to run '$cmd'\n" if ($debug);
	sleep 1 if ($debug);
	my $events_str=`$cmd`;
	my $obj= $json->decode($events_str);
	#print Dumper($obj) ;
	#print Dumper($obj->{'EventStatus'}[0]->{'Event'}[1]->{'EventDetails'}[0]->{'NotBefore'});
   
	foreach ( @{ $obj->{'EventStatus'} }) {
		#print Dumper($_);

		# Event Array 0 is the InstanceID
		# Event Array 1 is all the EventDetails
				
		$tmp_instance_id= $_->{'Event'}[0]->{'InstanceId'};  # String
		$event_date_hash{$tmp_instance_id}=$_->{'Event'}[1]->{'EventDetails'}[0]->{'NotBefore'};  # String
		$event_code_hash{$tmp_instance_id}=$_->{'Event'}[1]->{'EventDetails'}[0]->{'Code'};  # String
		$event_description_hash{$tmp_instance_id}=$_->{'Event'}[1]->{'EventDetails'}[0]->{'Description'};  # String
	}
}

####################################################################
# Sub for looking up AWS Name Tag from the instance-id
####################################################################
sub get_aws_name_hash {
	my $region=shift;
	my $tmp_instance_id; # temperary just for this
	my $cmd ="aws ec2 describe-tags --region $region --filters 'Name=resource-type,Values=instance' Name=key,Values=Name --query '{Tags:Tags[]}' ";
	print "About to run '$cmd'\n" if ($debug);
	sleep 5 if ($debug);
	my $aws_name_results_str=`$cmd`;
	my $obj= $json->decode($aws_name_results_str);
	# print Dumper($obj) ;
	foreach ( @{ $obj->{'Tags'} }) {
		# print Dumper($_);
		$tmp_instance_id=$_->{'ResourceId'} ;                 # ResourceID is the instance id
		$instance_name_hash{$tmp_instance_id}=$_->{'Value'} ; # Value is the Name of the instance, since we used "Name=key,Values=Name" in our query
	}
		
}


##################################
# Print and return the data
##################################
sub print_results{
	$count=0;
	# Return the list sorted by date.  Soonest first.
	foreach my $tmp_instance_id (sort { $event_date_hash{$a} cmp $event_date_hash{$b} } keys %event_date_hash ) {
		next if ($nagios && $event_description_hash{$tmp_instance_id}=~ /Completed/) ; # if nagios flag do not print completed.
		next if ($nagios && $event_description_hash{$tmp_instance_id}=~ /Canceled/) ;  # if nagios flag do not print canceled.
		printf("%-13.13s %-20.20s %-8s %-20s %-25s\n", $event_date_hash{$tmp_instance_id}, $instance_name_hash{$tmp_instance_id}, $tmp_instance_id,$event_code_hash{$tmp_instance_id}, $event_description_hash{$tmp_instance_id});
		$count++;
	}
	print $count . " AWS Events to report.\n" if ($nagios);  # Return something 
}
##################################
#  Exit code for Nagius
##################################
sub exit_code_for_nagios {
	if ($count > 0 ) {
		exit 2; # return Critical
	} else {
		exit 0; # return Ok
	}
}

exit 3; #Unknown.  Something else happened


