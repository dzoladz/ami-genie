#!/bin/bash

######################
# Requires:
# 	1. instances to be tagged with a key:value of Backup:true to be captured for backup processing
#	2. IAM established with permissions to perform backup tasks on EC2
#
# Notes:
# In AWS Console, set instance 'Backup' value to true. This is the primary hook for this script identify the instance for AMI creation.
# ami-genie.sh creates AMI with the string of 'ami-genie' in the description. The presense of 'ami-genie' in the description
# creates the primary hook to identify those AMIs that should be rotated on RETENTION schedule.
#
#
# SET SCRIPT VARS
RETENTION='30' #Retention period for AMIs, Number of days
OWNERID=''  # Account number of image owner, i.e. OwnerId
#
######################



## CREATE AMI PROCESS
# If tag 'backup' set to 'true' in AWS Console, grab instance id
instances_to_backup=(`aws ec2 describe-instances --filters "Name=tag:Backup,Values=true" --query "Reservations[*].Instances[*].InstanceId[]" --output text`)

# iterate through $instances_to_backup, add 'ami-genie' as the deregister hook to check
for i in ${instances_to_backup[@]}
do
NAME='AMI for instance '$i
DES='Created by ami-genie script'
        aws ec2 create-image --instance-id $i --name "$NAME" --description "$DES" # --dry-run # NEED TO REMOVE DRY RUN FOR LIVE
done


## AMI DEREGISTRATION PROCESS
#create deregistration date 
NOW=$(date +'%Y-%m-%d')
DEREGISTER_DATE=$(date --date="${NOW} -${RETENTION} day" +%Y-%m-%d)

#create list of AMIs to deregister
ami_dereg_list=(`aws ec2 describe-images --owner $OWNERID --filters "Name=description,Values=*ami-genie*" --query "Images[?CreationDate<='$DEREGISTER_DATE']" --output table | grep ImageId | awk '{print $4}'`)

# iterate through $ami_dereg_list and deregister
for t in ${ami_dereg_list[@]}
do
        aws ec2 deregister-image --image-id $t # --dry-run # NEED TO REMOVE DRY RUN FOR LIVE
done 
