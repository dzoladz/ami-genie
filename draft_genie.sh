#!/bin/bash

######################
# Requires: 
# 	1. instances to be tagged with a key:value of Backup:true to be captured for backup processing
#	2. IAM established with permissions to perform EC2 tasks
# 
# SET SCRIPT VARS
RETENTION='29' #Retention peroid for AMIs, Number of days 
OWNERID='ACCOUNTNUMBER'  # Account number of image owner, i.e. OwnerId 
#
######################



## CREATE AMI PROCESS
# If tag 'backup' set to 'true' in AWS Console, grab instance id
instances_to_backup=(`aws ec2 describe-instances --filters "Name=tag:Backup,Values=true" --query "Reservations[*].Instances[*].InstanceId[]" --output text`)

# iterate through $instances_to_backup
for i in ${instances_to_backup[@]}
do
NAME='AMI_of_'$i
DES='Scripted_AMI_Creation'
        aws ec2 create-image --instance-id $i --name $NAME --description $DES --dry-run # NEED TO REMOVE DRY RUN FOR LIVE
done 


## AMI DEREGISTRATION PROCESS
#create deregistration date 
NOW=$(date +'%Y-%m-%d')
DEREGISTER_DATE=$(date --date="${NOW} -${RETENTION} day" +%Y-%m-%d)

#create list of AMIs to deregister
ami_dereg_list=(`aws ec2 describe-images --owner $OWNERID --query "Images[?CreationDate>='$DEREGISTER_DATE']" --output table | grep ImageId | awk '{print $4}'`)

# iterate through $ami_dereg_list and deregister
for t in ${ami_dereg_list[@]}
do
        aws ec2 deregister-image --image-id $t --dry-run # NEED TO REMOVE DRY RUN FOR LIVE
done 
