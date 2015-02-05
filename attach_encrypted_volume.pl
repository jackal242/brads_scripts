#!/usr/bin/perl
#####################################################
# The purpose of this script is to allow the user
# to attach a volume to an instance easily and quickly
#####################################################
use Getopt::Long;
use strict ;
use Data::Dumper ;

$| = 1; # do not buffer output

##########################################
# My's
##########################################
my $hostname;
my $size;
my $quiet;
my $verbose;
my $aws_lookup="/usr/local/admin/scripts/aws_lookup";  	# This is a script I wrote that returns all the aws meta data about a given
							# instance.  I can pass it a hostname it will match on the instance NAME= tag.
							# I'm using it to collect the instance_id and region for the host.
							# You'll need to write something like this and adjust the script accordingly.
my $av_zone;
my $debug;
my $instance_id;
my $availibility_zone ;
my $region ;
my $instance_id ;
my $ec2_bin_dir="/usr/local/admin/ec2/bin";		# Home directory for ec2-tools.  I know they are old and replaced by 
							# the aws-tools.  But I still use the ec2-tools.
my $volume ;
my $diskname;
my $linux_diskname;
my $mountname;
my $default_diskname="/dev/sdp";
my $default_mountname="/encrypt";
my $instance_type;
my $sshcmd ="ssh -l root";				# If you have any special keys access, add them here.
my $volume_group="autovg00";				# Default volume group name
my $logical_volume="lv00";				# Default logical volume name
my $lvm=0;

##########################################
# Get Passed in options
##########################################
my $result = GetOptions (
   "hostname=s"    => \$hostname,  # string, hostname-foo-01
   "diskname:s"    => \$diskname,  # string, sdf through sdp, default is sdp (: means optional)
   "mountname:s"   => \$mountname, # string, default is /encrypt
   "size=i"        => \$size,      # integer
   "quiet"         => \$quiet,     # flag
   "lvm"           => \$lvm,       # flag
   "verbose"       => \$verbose);  # flag

##########################################
# Vet options
##########################################
usage() if (! defined $hostname || ! defined $size);
$debug=1 if ($verbose);
$diskname=$default_diskname if (! defined $diskname);
if ($diskname !~ /\/dev\/sd[fghijklmnop]/) {
	die "Diskname must be /dev/sdf through /dev/sdp\n";
}
$linux_diskname=$diskname;
$linux_diskname=~ s/sd/xvd/;  # so sdf becomes xvdf in the OS
$mountname=$default_mountname if (! defined $mountname);
# print "      Diskname = $diskname\n" if ($debug);
# print "Linux Diskname = $linux_diskname\n" if ($debug);
# print "    Mount Name = $mountname\n" if ($debug);

##########################################
# Usage
##########################################
sub usage {
	print "Usage:\n";
	print " $0 -h hostname -s size" . "\n";
	print "\n";
	print "Example(s):\n";
	print " $0 -h hostname-foo-01 -s 20 -lvm \n";
	print " $0 -h hostname-foo-01 -s 111 -d /dev/sdp -m /hello -lvm\n";
	exit;

}

##########################################
#  Main
##########################################
get_instance_details();
prompt_to_continue();
create_volume();
name_volume_in_amazon();
attach_volume();
confirm_disk_attached();
lvm_disk_pvcreate() if ($lvm);
lvm_disk_confirm() if ($lvm);
lvm_disk_vgcreate() if ($lvm);
lvm_disk_lvcreate() if ($lvm);
format_disk();
verify_format_disk();
create_mount_point();
mount_disk();


##########################################
# Get details about the instance
##########################################
sub get_instance_details {
	my $cmd="$aws_lookup -f ^$hostname";
	print "About to run : $cmd \n";
	my $results=`$cmd`;
	chomp($results);
	# $results =~ s/^\s+//;  #left trim
	# $results =~ s/\s+$//;  #right trim
	# print $results; 
	if ( $results =~ /(us\-....\-.[abcd])/ ) {
		print "---> $1 in $results\n";
		$availibility_zone = $1 ;
	} else {
		die "Unable to determine availibility_zone for $hostname. \n $results\n";
	}
	$region = $availibility_zone;
	chop($region);		# remove the last character so us-east-1a become us-east-1

	if ( $results =~ /INSTANCE\t(i\-........)/ ) {
		$instance_id=$1
	} else {
		die "Unable to determine instance_id for $hostname. \n $results\n";
	}

	$instance_type=(split(/\s+/, $results))[11];	
	# print "TYPE=$instance_type";
	if ($instance_type=~/^m1/) { die "$instance_type does not support Encrypted EBS volumes.  Exiting.... " };

	#print "Availibility Zone = $availibility_zone \n" if ($debug);
	#print "Region            = $region \n" if ($debug);
	#print "Instance ID       = $instance_id \n" if ($debug);
}

##########################################
# Prompt User
##########################################
sub prompt_to_continue {
	print_all_variables();
	print "Create Volume? [y/n] ";
	my $continue = <STDIN>; # I moved chomp to a new line to make it more readable
	chomp $continue; # Get rid of newline character at the end
	exit 0 if ($continue ne "y"); # If empty string, exit.
}

##########################################
# Create volume
##########################################
sub create_volume {
	my $cmd = "$ec2_bin_dir/ec2-create-volume -s $size --region $region --encrypted -t gp2 -z $availibility_zone";
	print "About to run -> $cmd \n";
	my $results = `$cmd`;
	$volume= (split(/\s+/, $results))[1];	
	if ($volume =~ /vol-/) {
		print "Volume            = $volume \n" if ($debug);	
	} else {
		die "Unable to create volume for $hostname. \n VOLUME CREATE CMD RESULTS=$results\n";
	}
}

##########################################
# Name the volume in Amazon
##########################################
sub name_volume_in_amazon {
	my $cmd = "$ec2_bin_dir/ec2-create-tags --region $region $volume --tag \"Name=$hostname:${diskname}:${size}GB-volume\"";
	print "About to run -> $cmd \n";
	my $results = `$cmd`;
	if ($results =~ /TAG\tvolume/) {
		print "Volume tagged\n" if ($debug);	
	} else {
		die "Unable to create volume for $hostname. \n CREATE TAG CMD RESULTS=$results\n";
	}
}

##########################################
# Attach Volume
##########################################
sub attach_volume {
	# First wait for the volume to come up.
	my $availible = 0 ;
	while ($availible== 0) {
		my $cmd="$ec2_bin_dir/ec2-describe-volumes --region $region $volume";
		print "About to run -> $cmd \n";
		my $results = `$cmd`;
		if ($results =~ /available/) {
			print "Volume created.\n" if ($debug);	
			$availible=1;
		} else {
			print "Volume creating\n";
			sleep 10;
		}
	}

	# Then attach it
	my $cmd="$ec2_bin_dir/ec2-attach-volume $volume -i $instance_id --region $region -d $diskname";
	print "About to run -> $cmd \n";
	my $results = `$cmd`;
		
	if ($results =~ /attaching/) {
		print "Attaching volume...\n" if ($debug);	
	} else {
		die "Something went wrong attaching the volume: $volume ";
	}

	# Now wait for it to attach
	my $attached = 0 ;
	while ($attached== 0) {
		my $cmd="$ec2_bin_dir/ec2-describe-volumes --region $region $volume";
		print "About to run -> $cmd \n";
		my $results = `$cmd`;
		if ($results =~ /attached/) {
			print "Volume $volume attached to $hostname as $linux_diskname.\n" if ($debug);	
			$attached=1;
		} else {
			print "Attaching volume... \n";
			sleep 10;
		}
	}
	
}

sub print_all_variables {
	print "------------------------------------------------" . "\n" ;
	print "         Hostname = $hostname \n" ;
	print "             Size = $size GB \n" ;
	print "Availibility Zone = $availibility_zone \n" ;
	print "           Region = $region \n"  ;
	print "      Instance ID = $instance_id \n"  ;
	print "         Diskname = $diskname\n" ;
	print "   Linux Diskname = $linux_diskname\n" ;
	print "       Mount Name = $mountname\n" ;
	print "------------------------------------------------" . "\n" ;
}


sub confirm_disk_attached {
	# Confirm that it's actually attached
	my $cmd ="$sshcmd $hostname fdisk -l |grep -A5 $linux_diskname";
	print "About to run -> $cmd" . "\n";
	my $results=`$cmd`;
	# print $results;
	if ($results =~ /Disk $linux_diskname/) {
		print "Disk $linux_diskname confirmed attached\n";
	} else {
		die "$linux_diskname does not show up in fdisk -l on $hostname\n";
	}
}

sub lvm_disk_pvcreate {
	my $cmd ="$sshcmd $hostname /sbin/pvcreate $linux_diskname";
	print "About to run -> $cmd" . "\n";
	my $results=`$cmd`;
	# print $results;
	if ($results =~ /successfully created/) {
		print "$results";
	} else {
		die "pvcreate for $linux_diskname failed on $hostname\n";
	}
}

sub lvm_disk_confirm {
	my $cmd ="$sshcmd $hostname /sbin/pvscan";
	print "About to run -> $cmd" . "\n";
	my $results=`$cmd`;
	# print $results;
	if ($results =~ /PV $diskname/) {
		print "Confirmed pvcreate successful\n";
	} else {
		die "pvcreate for $linux_diskname failed on $hostname.  Check pvscan.... \n";
	}
}

sub lvm_disk_vgcreate {
	my $cmd ="$sshcmd $hostname /sbin/vgcreate $volume_group $linux_diskname";
	print "About to run -> $cmd" . "\n";
	my $results=`$cmd`;
	# print $results;
	if ($results =~ /Volume group.*successfully created/) {
		print "$results";
	} else {
		print "$results";
		die "vgcreate for $linux_diskname failed on $hostname.  Check pvscan.... \n";
	}
}

sub lvm_disk_lvcreate {
	my $cmd ="$sshcmd $hostname /sbin/lvcreate -l 100%VG -n $logical_volume $volume_group";
	print "About to run -> $cmd" . "\n";
	my $results=`$cmd`;
	# print $results;
	if ($results =~ /Logical volume.*created/) {
		print "$results";
		$linux_diskname="/dev/${volume_group}/${logical_volume}";
		print "Resetting Linux Diskname to LV Path ($linux_diskname)\n";
	} else {
		die "vgcreate for $linux_diskname failed on $hostname.  Check pvscan.... \n";
	}
}

sub format_disk {
	my $cmd ="$sshcmd $hostname /sbin/mkfs -t ext4 $linux_diskname";
	print "About to run -> $cmd" . "\n";
	my $results=`$cmd`;
}

sub verify_format_disk {
	my $cmd ="$sshcmd $hostname /usr/bin/file -sL $linux_diskname";
	print "About to run -> $cmd" . "\n"  ;
	my $results=`$cmd`;
	chomp($results);
	#print "'$results'";
	if ($results =~ /ext4 filesystem data/) {
		print "Disk $linux_diskname formatted as ext4 \n";
	} else {
		die "Problem formatting $linux_diskname $hostname\n";
	}
}

sub create_mount_point {
	my $cmd ="$sshcmd $hostname mkdir -p $mountname";
	print "About to run -> $cmd" . "\n"  ;
	my $results=`$cmd`;
	chomp($results);
	if ($results ne "") {
		print "RESULTS: '$results'";
	}
}

sub mount_disk {
	my $cmd ="$sshcmd $hostname /bin/mount $linux_diskname $mountname";
	print "About to run -> $cmd" . "\n"  ;
	my $results=`$cmd`;
	chomp($results);
	if ($results ne "") {
		print "RESULTS: '$results'";
	}
	exit;
}
