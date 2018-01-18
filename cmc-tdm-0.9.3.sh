#!/bin/bash

# Created by Sam Rogers			12/01/2011

# CMC tamper detection mechanism
#
# This script will test to see if new file has be added or remove to the CMC since a baseline was taken.
#

# You can define the hostname here if you want or let it find it in the /etc/hosts file.
# This will require that the cmc for the UV is the only CMC define in the /etc/hosts
# 
# This presumes that the CMC has the ssh-key from *-SMS system so this can run automatically
# without entering a password for the CMC.

#set -x

# CMC Directory filter, which will filter out to directories that to dynamic.
#DirFilter="/dev|/sys|/proc|/tmp|/store/var/run|/store/var/log/messages*|/var/run|/var/log/messages"
DirFilter="/dev|/sys|/proc|/tmp|/store/var/run|/store/var/log/messages*|/var/run|/var/log/messages"

# Set the home directory path.
HomePath="/root/cmc_tdm"

# You can manually in the hostname if you like.
#Hostname="SomeHost-Name"
Hostname=

# Set Testing varible on=true or off=false.
Testing=false

# Print progress when testing.
print_progress ()
{
	printf "."
	exit
}

# Fucntion: create_current ()
# Create current function to do a current listing of the CMC and create a checksum file
create_current ()
{
	# create the current .out and .md5 files.
	current_cmc_output_find=`ssh $Hostname find / -print 2> /dev/null` 
	current_cmc_output_grep=`printf "$current_cmc_output_find" | egrep -v $DirFilter | tee $HomePath/cmc_current.out` 
   current_cmc_chksum=`md5sum $HomePath/cmc_current.out | awk '{print $1}' | tee $HomePath/cmc_current-md5`

	# And so just print to sysout a tick to show progress of creating the currnet.
	Check_if_Testing && printf "TESTING: The cmc_current.out and cmc_current-md5 files have been created. \n" | tee -a /var/log/cmc_tdm.log
}

# Fucntion: create_baseline_out_chksum ()
# Create baseline .out and .md5 checksum files.
create_baseline_out_chksum ()
{
		# Creating the cmc_baseline.out & cmc_baseline-md5
		baseline_cmc_baseline_find=`ssh $Hostname find / -print 2> /dev/null` 
		baseline_cmc_baseline_grep=`printf "$baseline_cmc_baseline_find" | egrep -v $DirFilter > $HomePath/cmc_baseline.out`
		baseline_cmc_chksum=`md5sum $HomePath/cmc_baseline.out | awk '{print $1}' | tee $HomePath/cmc_baseline-md5 `
		printf "For $Hostname cmc_baseline.out and cmc_baseline-md5 files have been created. \n" | tee -a /var/log/cmc_tdm.log
}

# Fucntion: check_n_archive_for_baseline_md5 ()
check_n_archive_for_baseline_md5 ()
{
# Check if baseline checksum file is there and archive it if it is.
	if [ -e $HomePath/cmc_baseline-md5 ]
	then
		timestamp=`date '+%m%d%y.%H%M%S'` 
		mv $HomePath/cmc_baseline-md5 $HomePath/cmc_baseline-md5-$timestamp
		printf "A cmc_baseline-md5 was present and has been archived. \n" | tee -a /var/log/cmc_tdm.log
		ls -l $HomePath/cmc_baseline-md5-$timestamp >> /var/log/cmc_tdm.log
	fi
}

# Fucntion: check_n_archive_for_baseline_out ()
check_n_archive_for_baseline_out ()
{
# Check if baseline .out file is there and archive it if it is.
	if [ -e $HomePath/cmc_baseline.out ]
	then
		timestamp=`date '+%m%d%y.%H%M%S'` 
		mv $HomePath/cmc_baseline.out $HomePath/cmc_baseline.out-$timestamp
		printf "A cmc_baseline.out was present and has been archived. \n" | tee -a /var/log/cmc_tdm.log
		ls -l $HomePath/cmc_baseline.out-$timestamp >> /var/log/cmc_tdm.log
	fi
}

#  Check_if_hostname_is_set: 
#	Checks if the ENV $Hostname is set and if it is not gets it from /etc/hosts.
Check_if_hostname_is_set ()
{
	#  Check to see if Hostname is set. If not set it to the current Hostnamese.:
	if [ -z "$Hostname" ]
	then
		#  Grep the CMC hostname out of the /etc/hosts file and create the Hostname varible.
		Hostname=`grep cmc /etc/hosts | awk '{print $2}'`
		Check_if_Testing && printf "\$Hostname is: $Hostname \n" >> /var/log/cmc_tdm.log
	else
		#  Hostname is being predifined.
		Check_if_Testing && printf "\$Hostname is pre-defined: $Hostname\n" >> /var/log/cmc_tdm.log 
	fi
}

# Fuction: Check_if_Testing: Checks to see if Testing is turned on (true) or not.
Check_if_Testing ()
{
	if $Testing
	then
		return 0
	else
		return 1
	fi
}

# Get command line options with getopts btp name
get_cmdline_options ()
{
	while getopts btrTp name
	do
    	case $name in
			b)	# Option -b; create a new baseline.
				# Check if baseline .out file is there and archive it if it is.
				#  Check_if_hostname_is_set: 
				Check_if_hostname_is_set 

				check_n_archive_for_baseline_out 

				# Check if baseline checksum file is there and archive it if it is.
				check_n_archive_for_baseline_md5 

				# Create the cmc_baseline.out & cmc_baseline-md5
				create_baseline_out_chksum
				exit
				;;

			t)	# t) command line option for turning on Testing boolean
				Testing=true
				;;

			r)	# r) command line option for reboot CMC.
				Check_if_Testing && printf "Reboot CMC:1 Test case option is working:\n" 
				printf "Reboot CMC:2 option is working:\n" | tee -a /var/log/cmc_tdm.log
				exit
				;;

			T)	# T) command line option for to just a test to make sure the case statement is working.
				Check_if_Testing && printf "Test for command line options are working:\n" 
				exit
				;;

			p)	# p) command line option to print out what the options are for this command:
				printf "Usage: %s: [-b] [-t] [-r] \n" $0
				exit
				;;
          
			?)	# ?) command line option that defaults if not options are given and will fall throught:
				#  Check_if_hostname_is_set: 
				Check_if_hostname_is_set 

				printf "\n" $0
				exit 2;;

		esac
	done
}

# Fuction Check_if_directory_is_created: Check to see if the directory has been created and if not create it.
Check_if_directory_is_created ()
{
	if [ ! -d $HomePath ]
	then
		# $HomePath has not been created; create it.
		Check_if_Testing && printf "$HomePath directory has NOT been created:\n" 
		mkdir -p $HomePath
	else
		# If the path is there just print out a message to show progress.
		Check_if_Testing && printf "$HomePath directory has been created already:\n" 
	fi
}

# =============================================================================
# Start of cmc_tdm
# =============================================================================

# print the date stamp to cmc_tdm.log to separate logging by timestamps.
printf "\n===== `date` =======\n"  >> /var/log/cmc_tdm.log

# Get command line options with getopts btp name
get_cmdline_options $1

# Check to see if the directory has been created and if not create it.
Check_if_directory_is_created 

#	Check to see if baseline output file has not been md5 checksumed and if not create it.
if [ ! -e $HomePath/cmc_baseline-md5 ]
then

	#	First check to see if baseline output file has not been created and if not report it to the screen and cmc_tdm.log.
	if [ ! -e $HomePath/cmc_baseline.out ]
	then
	
		#	Ask the user to manually create the baseline re-running the script witht he -b option.
		printf "The cmc_baseline.out file is not detected and needs to be created: Please re-run witht he correct option. \n" | tee -a /var/log/cmc_tdm.log

		#	We do not want to proceed futher because the baseline needs to be created manually.
		exit 2

	# else if the cmc_baseline.out is there.
	else

		# If the cmc_baseline.out file is there report to log file with a timestamp.
		printf "The /var/log/cmc_tdm.out is there:" | tee -a /var/log/cmc_tdm.log
		ls -l $HomePath/cmc_baseline.out >> /var/log/cmc_tdm.log

	fi

	#	If we servived this far, the baseline.out file is there but the chksum is not. So create it.
	baseline_cmc_chksum=`md5sum $HomePath/cmc_baseline.out | awk '{print $1}' | tee $HomePath/cmc_baseline-md5 `

	# If the cmc_baseline.-md5 file is there report to log file with a timestamp.
		printf "The /var/log/cmc_tdm-md5 is there:" | tee -a /var/log/cmc_tdm.log
		ls -l $HomePath/cmc_baseline-md5 >> /var/log/cmc_tdm.log

	# Call the create_current funtion.
	create_current

# else if the cmc_baseline-md5 is there.
else

	# The baseline checksum file is there, so create the comparison varible to with a current check varible that is created next.
	baseline_cmc_chksum=`awk '{print $1}' $HomePath/cmc_baseline-md5`

	# And so just print to sysout a tick to show progress of creating the check sum.
#	printf "+"

	# Call the create_current funtion.
	create_current

fi

# Function: regularlog_out: To Pring out regular successfull information to a log file.
Regularlog_output ()
{

	printf "The \$baseline_cmc_chksum is: $baseline_cmc_chksum \n" | tee -a /var/log/cmc_tdm.log
	printf "The \$current_cmc_chksum  is: $current_cmc_chksum \n" | tee -a /var/log/cmc_tdm.log
	printf "CMC Tamper Detection Monitor for $Hostname: Completed Successfully no tamper detected.\n\n" | tee -a /var/log/cmc_tdm.log

}

# Function: errlog_output: To Pring out error output information to the screen and the _err.log file.
Errlog_output ()
{
	printf "===== `date` =======\n"  | tee -a /var/log/cmc_tdm_err.log
	printf "CMC Tamper Detection Monitor for $Hostname: Failed\n\n" | tee -a /var/log/cmc_tdm_err.log
	printf "CMC Tamper Detection Monitor for $Hostname: Failed\n\n" >> /var/log/cmc_tdm.log

	printf "The \$baseline_cmc_chksum is: $baseline_cmc_chksum \n" | tee -a /var/log/cmc_tdm_err.log
	printf "The \$current_cmc_chksum  is: $current_cmc_chksum \n\n" | tee -a /var/log/cmc_tdm_err.log

	printf "The diff between Baseline            and     Current is:\n" >> /var/log/cmc_tdm.log
	diff_full_output=`diff -y --suppress-common-lines -W 80 /root/cmc_tdm/cmc_baseline.out /root/cmc_tdm/cmc_current.out`
	printf "$diff_full_output\n" >> /var/log/cmc_tdm_err.log
	printf "=================================================================================\n\n" | tee -a /var/log/cmc_tdm_err.log
#	ssh back into the cmc and use the diff to do a long listing of just the files that are differenet from the baseline to current.
	ssh $Hostname ls -l `diff --suppress-common-lines -W 80 /root/cmc_tdm/cmc_baseline.out /root/cmc_tdm/cmc_current.out | grep '>' | cut -d ' ' -f 2` | tee -a  /var/log/cmc_tdm_err.log
	printf "=================================================================================\n\n" | tee -a /var/log/cmc_tdm_err.log
}

#Fuction: Querry_restart_cmc: The chksum between baseline and current did not match. Querry user to
# see if a cmcclean should be run and if so run it.
Querry_restart_cmc ()
{
	
	Check_if_Testing && printf "Testing: Querry_restart_cmc completed successfully \n" 

}

#if $current_cmc_chksum equals $baseline_cmc_chksum then report Success, else Failure.
if [ $current_cmc_chksum == $baseline_cmc_chksum ]
then	
	# Calling/Testing regularlog_output (), if function successful run poweronoff.sh to shutdown 
	if Regularlog_output
	then
		Check_if_Testing && printf "Success: Regularlog_output completed successfully \n" 
		./test-poweroff.sh
	else
		Check_if_Testing && printf "Error: Fuction: Regularlog_output had a unknown problem.\n" | tee -a /var/log/cmc_tdm_err.log
	fi

else
	# Calling/Testing Errlog_output (), if function successful run poweronoff.sh to shutdown 
	if Errlog_ouput
	then
		Check_if_Testing && printf "Success: Errlog_output completed successfully \n" 
	else
		Check_if_Testing && printf "Error: Fuction: Errlog_output had a unknown problem.\n" | tee -a /var/log/cmc_tdm_err.log
		Querry_restart_cmc
fi
