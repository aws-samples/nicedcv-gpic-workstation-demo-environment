#!/bin/bash
# =============================================================================
# FOR NON-PRODUCTION USE ONLY
# =============================================================================
# #1 In the AWS console, open AWS CloudShell (either by searching or clicking the terminal icon in the top bar)
# #2 Click on Actions > Upload file to upload this script
# #3 Type . nicedcv-gpic-workstation -help to get overview of available commands.
# =============================================================================
INSTANCETYPE=g4dn.4xlarge
VOLUMESIZE=250
VOLUMETYPE=gp2
TAGPREFIX=nicedcv-quicudp-demo
VPCCIDR=172.17.173.192/28
VPCSUBNETPUBLICACIDR=172.17.173.192/28
# You will need to manually subscribe to the NICE-DCV EC2 image on AWS Marketplace:
# https://aws.amazon.com/marketplace/pp/prodview-3k22gxh7x7kdy
NICEDCVPRODUCTCODE=5kui34zsdoxkj54pr1igh59x1
# =============================================================================
LIGHTRED="\e[91m"
LIGHTGREEN="\e[92m"
LIGHTYELLOW="\e[93m"
LIGHTBLUE="\e[94m"
LIGHTMAGENTA="\e[95m"
LIGHTCYAN="\e[96m"
WHITE="\e[97m"
ENDCOLOR="\e[0m"

SCRIPTNAME=$(basename $BASH_SOURCE)
# =============================================================================
# Resource setup
# ------------------------
# These are included on CloudShell, just making sure everything is up-to-date.
TEMP=$((sudo yum -y install jq gettext bash-completion moreutils) 2>&1)

#Ensuring AWS region is set in configuration
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
TEMP=$((echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile) 2>&1)
TEMP=$((echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile) 2>&1)
aws configure set default.region ${AWS_REGION}
# =============================================================================
# User input/command handling.
# -----------------
case "$1" in
  -c|-create)
    if [ -n "$2" ] && [ ${2:0:10} = "--hostname" ] && [ -n "$3" ]; then
      USERCHECK=$((aws ssm describe-parameters --parameter-filters Key=Name,Option=Equals,Values=${TAGPREFIX}-$3 | jq '.Parameters[0].Name') 2>&1)
      if [ "${USERCHECK:1:-1}" = "${TAGPREFIX}-$3" ]
      then
        echo -e "${LIGHTRED}Environment and workstation already exists for this user. Delete SSM parameter${LIGHTMAGENTA} ${TAGPREFIX}-$3 ${LIGHTRED}to remove this check.${ENDCOLOR}"
        RUNOPTION=-1
      else
        HOSTNAME=$3
        RUNOPTION=1
      fi
    else
      echo -e "${LIGHTRED}Error: Incorrect syntax for${LIGHTYELLOW} $1${LIGHTRED}, expecting ${LIGHTCYAN}. ${SCRIPTNAME} -create --hostname yourhostname ${LIGHTRED}format${ENDCOLOR}" >&2
      RUNOPTION=-1
    fi
    ;;
  -li|-login)
    if [ -n "$2" ] && [ ${2:0:10} = "--hostname" ] && [ -n "$3" ] && [ -n "$4" ] && [ ${4:0:4} = "--ip" ] && [ -n "$5" ]; then
      USERCHECK=$((aws ssm describe-parameters --parameter-filters Key=Name,Option=Equals,Values=${TAGPREFIX}-$3 | jq '.Parameters[0].Name') 2>&1)
      if [ "${USERCHECK:1:-1}" = "${TAGPREFIX}-$3" ]
      then
        if valid_ip "$5"; then
          HOSTNAME=$3
          IPADDR=$5
          RUNOPTION=2
        else
          echo -e "${LIGHTRED}Error: Invalid IP address${LIGHTYELLOW} $5 ${ENDCOLOR}" >&2
          RUNOPTION=-1
        fi
      else
        echo -e "${LIGHTRED}Error: Specified user${LIGHTYELLOW} $3 ${LIGHTRED}does not have an environment provisioned. Create the environment first or check inputs.${ENDCOLOR}" >&2
        RUNOPTION=-1
      fi
    else
      echo -e "${LIGHTRED}Error: Invalid syntax for${LIGHTYELLOW} $1${LIGHTRED}, expecting${LIGHTCYAN} . ${SCRIPTNAME} -login --hostname ${LIGHTYELLOW}yourhostname ${LIGHTCYAN}--ip ${LIGHTYELLOW}yourip ${LIGHTRED}format${ENDCOLOR}" >&2
      RUNOPTION=-1
    fi
    ;;
  -lo|-logout)
    if [ -n "$2" ] && [ ${2:0:10} = "--hostname" ] && [ -n "$3" ]; then
      USERCHECK=$((aws ssm describe-parameters --parameter-filters Key=Name,Option=Equals,Values=${TAGPREFIX}-$3 | jq '.Parameters[0].Name') 2>&1)
      if [ "${USERCHECK:1:-1}" = "${TAGPREFIX}-$3" ]
      then
        HOSTNAME=$3
        RUNOPTION=3
      else
        echo -e "${LIGHTRED}Error: Specified user${LIGHTYELLOW} $3 ${LIGHTRED}does not have an environment provisioned. Create the environment first or check inputs.${ENDCOLOR}" >&2
        RUNOPTION=-1
      fi
    else
      echo -e "${LIGHTRED}Error: Incorrect syntax for${LIGHTYELLOW} $1${LIGHTRED}, expecting ${LIGHTCYAN}. ${SCRIPTNAME} -logout --hostname ${LIGHTYELLOW}yourhostname ${LIGHTRED}format${ENDCOLOR}" >&2
      RUNOPTION=-1
    fi
    ;;
  -d|-delete)
    if [ -n "$2" ] && [ ${2:0:10} = "--hostname" ] && [ -n "$3" ]; then
      USERCHECK=$((aws ssm describe-parameters --parameter-filters Key=Name,Option=Equals,Values=${TAGPREFIX}-$3 | jq '.Parameters[0].Name') 2>&1)
      if [ "${USERCHECK:1:-1}" = "${TAGPREFIX}-$3" ]
      then
        HOSTNAME=$3
        RUNOPTION=4
      else
        echo -e "${LIGHTRED}Error: Specified user${LIGHTYELLOW} $3 ${LIGHTRED}does not have an environment provisioned. Create the environment first or check inputs.${ENDCOLOR}" >&2
        RUNOPTION=-1
      fi
    else
      echo -e "${LIGHTRED}Error: Incorrect syntax for${LIGHTYELLOW} $1${LIGHTRED}, expecting ${LIGHTCYAN}. ${SCRIPTNAME} -delete --hostname ${LIGHTYELLOW}yourhostname ${LIGHTRED}format${ENDCOLOR}" >&2
      RUNOPTION=-1
    fi
    ;;
  -s|-status)
    TEMP=$((aws ec2 describe-vpcs --filters Name=cidr,Values=${VPCCIDR} Name=tag:Name,Values=${TAGPREFIX}-vpc | jq '.Vpcs[0]') 2>&1)
    if [ "${TEMP}" = "null" ]
    then
      echo -e "${LIGHTRED}Demo environment not detected. Create an environment first before running this command.${ENDCOLOR}" >&2
      RUNOPTION=-1
    else
      RUNOPTION=5
    fi
    ;;
  -h|-help)
    RUNOPTION=6
    ;;
  -*|--*=) # unsupported flags
    echo -e "${LIGHTRED}Error: Unsupported operation${LIGHTYELLOW} $1 ${LIGHTRED}Type ${LIGHTCYAN}. ${SCRIPTNAME} -help ${LIGHTRED} for supported syntax and usage.${ENDCOLOR}" >&2
    RUNOPTION=-1
    ;;
  *)
    echo -e "${LIGHTRED}Type ${LIGHTCYAN}. ${SCRIPTNAME} -help ${LIGHTRED}for supported syntax and usage.${ENDCOLOR}" >&2
    ;;
esac
# =============================================================================
# Code execution based on RUNOPTION value
# -----------------
case "$RUNOPTION" in
  -1)
    echo -e "${LIGHTRED}Operation aborted.${ENDCOLOR}"
    ;;
    # =============================================================================
    # -create --hostname ${HOSTNAME}
    # -----------------------------------------
  1)
    echo -e "${LIGHTGREEN}Creating workstation resources for user${LIGHTYELLOW} ${HOSTNAME} ${ENDCOLOR}"
    # =============================================================================
    INSTANCEPROFILENAME=gpicserverprofile-${HOSTNAME}
    INSTANCEROLENAME=gpicserverrole-${HOSTNAME}
    INSTANCEROLEPOLICY=gpicserverpolicy-${HOSTNAME}
    INSTANCEASSUMEROLEPOLICYDOCUMENT=gpicassumerolepolicy-${HOSTNAME}
    USERDATAFILENAME=gpic-userdata-${HOSTNAME}
    B64USERDATAFILENAME=b64gpic-userdata-${HOSTNAME}
    EC2CONFIGFILENAME=gpic-ec2config-${HOSTNAME}
    # =============================================================================
    # Resource setup
    # ------------------------
    # Checking if demo VPC already exists
    TEMP=$((aws ec2 describe-vpcs --filters Name=cidr,Values=${VPCCIDR} Name=tag:Name,Values=${TAGPREFIX}-vpc | jq '.Vpcs[0]') 2>&1)
    if [ "${TEMP}" = "null" ]
    then
      echo "[1/5]Creating VPC"
      VPCID=$((aws ec2 create-vpc --cidr-block ${VPCCIDR} --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${TAGPREFIX}-vpc},{Key=Group,Value=${TAGPREFIX}},{Key=Owner,Value=${HOSTNAME}}]" | jq '.Vpc.VpcId') 2>&1)
      echo "[2/5]Creating IGW"
      IGWID=$((aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${TAGPREFIX}-igw},{Key=Group,Value=${TAGPREFIX}},{Key=Owner,Value=${HOSTNAME}}]" | jq '.InternetGateway.InternetGatewayId') 2>&1)
      echo "[3/5]Attaching IGW to VPC"
      aws ec2 attach-internet-gateway --internet-gateway-id ${IGWID:1:-1} --vpc-id ${VPCID:1:-1}
      echo "[4/5]Creating Subnet"
      PUBLICSUBNETA=$((aws ec2 create-subnet --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${TAGPREFIX}-PublicSubnetA-${AWS_REGION}a},{Key=Group,Value=${TAGPREFIX}},{Key=Owner,Value=${HOSTNAME}}]" --availability-zone "${AWS_REGION}a" --cidr-block ${VPCSUBNETPUBLICACIDR} --vpc-id ${VPCID:1:-1}| jq '.Subnet.SubnetId') 2>&1)
      PUBLICROUTETABLEA=$((aws ec2 create-route-table --vpc-id ${VPCID:1:-1} | jq '.RouteTable.RouteTableId') 2>&1)
      PUBLICROUTEA=$((aws ec2 create-route --route-table-id ${PUBLICROUTETABLEA:1:-1} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGWID:1:-1} | jq '.Return') 2>&1)
      aws ec2 wait subnet-available --subnet-ids ${PUBLICSUBNETA:1:-1}
      echo "[5/5]Creating Route table association"
      PUBLICROUTETABLEAASSOCIATIONID=$((aws ec2 associate-route-table --subnet-id ${PUBLICSUBNETA:1:-1} --route-table-id ${PUBLICROUTETABLEA:1:-1} | jq '.AssociationId') 2>&1)
    else
      echo -e "${LIGHTBLUE}Network environment already configured, creating workstation configuration${ENDCOLOR}"
      VPCID=$((aws ec2 describe-vpcs --filters Name=cidr,Values=${VPCCIDR} Name=tag:Name,Values=${TAGPREFIX}-vpc | jq '.Vpcs[0].VpcId') 2>&1)
      PUBLICSUBNETA=$((aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPCID:1:-1} Name=cidr,Values=${VPCSUBNETPUBLICACIDR} | jq '.Subnets[0].SubnetId') 2>&1)
    fi

    echo "[1/5]Creating IAM Instance role, profile and policies"
    # The policy is scoped down to exactly what the server needs to work, plus the minimum policies to enable Systems Manager Session Manager so we can check what's happening on our live servers without needing to configure SSH and keys.
    # IAM creation operations have low TPS rates and can be throttled when applied in succession. We add some buffer time here.
    INSTANCEROLEPOLICYARN=$((aws iam create-policy --policy-name ${INSTANCEROLEPOLICY} --policy-document '{"Version": "2012-10-17","Statement": [{"Effect": "Allow","Action": ["s3:GetObject"],"Resource": ["arn:aws:s3:::dcv-license.'${AWS_REGION}'/*","arn:aws:s3:::aws-ssm-'${AWS_REGION}'/*","arn:aws:s3:::aws-windows-downloads-'${AWS_REGION}'/*","arn:aws:s3:::amazon-ssm-'${AWS_REGION}'/*","arn:aws:s3:::amazon-ssm-packages-'${AWS_REGION}'/*","arn:aws:s3:::'${AWS_REGION}'-birdwatcher-prod/*","arn:aws:s3:::patch-baseline-snapshot-'${AWS_REGION}'/*"]}]}' | jq '.Policy.Arn') 2>&1)
    sleep 3
    # Create role and attach our custom policy plus two more required for Systems Manager
    INSTANCEROLENAMEARN=$((aws iam create-role --role-name ${INSTANCEROLENAME} --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{"Sid": "","Effect": "Allow","Principal": {"Service": "ec2.amazonaws.com"},"Action": "sts:AssumeRole"}]}' | jq '.Role.Arn') 2>&1)
    sleep 3
    aws iam attach-role-policy --role-name ${INSTANCEROLENAME} --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
    sleep 3
    aws iam attach-role-policy --role-name ${INSTANCEROLENAME} --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
    sleep 3
    aws iam attach-role-policy --role-name ${INSTANCEROLENAME} --policy-arn ${INSTANCEROLEPOLICYARN:1:-1}
    sleep 3
    # Create instance profile. This is required for Systems Manager to work and is how we can easily configure Session Manager on bootstrap.
    IAMINSTANCEPROFILEARN=$((aws iam create-instance-profile --instance-profile-name ${INSTANCEPROFILENAME} | jq '.InstanceProfile.Arn') 2>&1)
    aws iam add-role-to-instance-profile --instance-profile-name ${INSTANCEPROFILENAME} --role-name ${INSTANCEROLENAME}
    echo "[2/5]Fetching latest AMI fetched from AWSMP"
    AMIID=$((aws ec2 describe-images --region ${AWS_REGION} --owners aws-marketplace --filters "Name=product-code,Values=${NICEDCVPRODUCTCODE}" --query "sort_by(Images, &CreationDate)[-1].[ImageId]") 2>&1)
    #trimming non-standard command output
    AMIID=${AMIID:7:-3}

    echo "[3/5]Creating security group"
    SGID=$((aws ec2 create-security-group --description ${TAGPREFIX} --group-name ${TAGPREFIX}-SG-${HOSTNAME} --vpc-id ${VPCID:1:-1} --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${TAGPREFIX}-SG-${HOSTNAME}},{Key=Group,Value=${TAGPREFIX}},{Key=Owner,Value=${HOSTNAME}}]" | jq '.GroupId') 2>&1)

    echo "[4/5]Creating EC2 launch configuration"
    cat <<-EOF > ${EC2CONFIGFILENAME}.json
      {
        "BlockDeviceMappings": [
            {
                "DeviceName": "/dev/xvda",
                "Ebs": {
                    "DeleteOnTermination": true,
                    "VolumeSize": ${VOLUMESIZE},
                    "VolumeType": "${VOLUMETYPE}"
                }
            }
        ],
        "ImageId": "${AMIID}",
        "InstanceType": "${INSTANCETYPE}",
        "Monitoring": {
            "Enabled": true
        },
        "SecurityGroupIds": [
            ${SGID}
        ],
        "SubnetId": ${PUBLICSUBNETA},
        "DryRun": false,
        "EbsOptimized": true,
        "IamInstanceProfile": {
            "Name": "${INSTANCEPROFILENAME}"
        },
        "InstanceInitiatedShutdownBehavior": "stop",
        "NetworkInterfaces": [
            {
                "AssociatePublicIpAddress": true,
                "DeleteOnTermination": true,
                "DeviceIndex": 0
            }
        ],
        "TagSpecifications": [
            {
                "ResourceType": "instance",
                "Tags": [
                  {
                    "Key": "Name",
                    "Value": "${TAGPREFIX}-${HOSTNAME}"
                  },
                  {
                    "Key": "Group",
                    "Value": "${TAGPREFIX}"
                  },
                  {
                    "Key": "Owner",
                    "Value": "${HOSTNAME}"
                  }
                ]
            }
        ],
        "MetadataOptions": {
            "HttpTokens": "optional",
            "HttpPutResponseHopLimit": 2,
            "HttpEndpoint": "enabled"
        }
      }
EOF

    sleep 10
    INSTANCEID=$((aws ec2 run-instances --cli-input-json file://${EC2CONFIGFILENAME}.json --region ${AWS_REGION} | jq '.Instances[0].InstanceId') 2>&1)
    echo "[5/5]Launching instance ${INSTANCEID:1:-1} (this will take a few minutes)..."
    aws ec2 wait instance-status-ok --instance-ids ${INSTANCEID:1:-1}
    rm ./${EC2CONFIGFILENAME}.json
    TEMP=$((aws ssm put-parameter --name ${TAGPREFIX}-${HOSTNAME} --value ${INSTANCEID:1:-1} --type String) 2>&1)
    echo -e "${LIGHTBLUE}Installation complete. Run script with ${LIGHTCYAN}. ${SCRIPTNAME} -login --hostname ${HOSTNAME} --ip ${LIGHTYELLOW}YOURCLIENTIP ${LIGHTBLUE}to set up the workstation for first connection.${ENDCOLOR}"
    ;;
    # =============================================================================
    # -login --hostname ${HOSTNAME} --ip ${IPADDR}
    # -----------------------------------------
  2)
    echo -e "${LIGHTGREEN}Connecting to workstation for user${LIGHTYELLOW} ${HOSTNAME} ${ENDCOLOR}"
    INSTANCEID=$((aws ssm get-parameter --name ${TAGPREFIX}-${HOSTNAME} | jq '.Parameter.Value') 2>&1)
    SGID=$((aws ec2 describe-instances --instance-ids ${INSTANCEID:1:-1} | jq '.Reservations[0].Instances[0].NetworkInterfaces[0].Groups[0].GroupId') 2>&1)
    IPCHECK=$((aws ec2 describe-security-groups --group-ids ${SGID:1:-1} | jq '.SecurityGroups[0].IpPermissions') 2>&1)
    if [ "$IPCHECK" = "[]" ]
    then
      TEMP=$((aws ec2 start-instances --instance-ids ${INSTANCEID:1:-1}) 2>&1)
      echo "[1/3]Launching instance ${INSTANCEID:1:-1} (this might take a few minutes)..."
      aws ec2 wait instance-running --instance-ids ${INSTANCEID:1:-1}
      echo "[2/3]Configuring network ingress"
      aws ec2 authorize-security-group-ingress --group-id ${SGID:1:-1} --protocol tcp --port 8443 --cidr ${IPADDR}/32
      aws ec2 authorize-security-group-ingress --group-id ${SGID:1:-1} --protocol udp --port 8443 --cidr ${IPADDR}/32
      PUBLICIPV4=$((aws ec2 describe-instances --instance-ids ${INSTANCEID:1:-1} | jq '.Reservations[0].Instances[0].PublicIpAddress') 2>&1)
      echo -e "${LIGHTBLUE}[3/3]Instance available at ${LIGHTMAGENTA}${PUBLICIPV4:1:-1} ${LIGHTBLUE} for user ${LIGHTMAGENTA}Administrator${ENDRESULT}"
      echo -e "${LIGHTBLUE}To set or reset the workstation password, go to the EC2 console, connect to your instance via Session Manager and when the Powershell prompt is active, type:"
      echo -e "${LIGHTCYAN}net user Administrator ${LIGHTYELLOW}\"Your_sufficientlyComplexPassw0rdindoublequotes!\"${ENDCOLOR}"
    else
      INGRESSIP=$((aws ec2 describe-security-groups --group-ids ${SGID:1:-1} | jq '.SecurityGroups[0].IpPermissions[0].IpRanges[0].CidrIp') 2>&1)
      if [ "${INGRESSIP:1:-1}" = "${IPADDR}/32" ]
      then
        echo -e "${LIGHTRED} Workstation already configured to connect at${LIGHTYELLOW} ${IPADDR} ${LIGHTRED}Check the EC2 Console to verify if the workstation is in RUNNING state.${ENDCOLOR}"
      else
        echo -e "${LIGHTRED}Workstation already configured to connect to${LIGHTMAGENTA} ${INGRESSIP:1:-4} ${LIGHTRED} Please disconnect from the instance using ${LIGHTCYAN}-logout --hostname${LIGHTYELLOW} ${HOSTNAME} ${LIGHTRED}and reconnect with your new IP.${ENDCOLOR}"
      fi
    fi
    ;;
    # =============================================================================
    # -logout --hostname ${HOSTNAME}
    # -----------------------------------------
  3)
    echo -e "${LIGHTGREEN}Disconnecting from workstation for user${LIGHTYELLOW} ${HOSTNAME} ${ENDCOLOR}"
    INSTANCEID=$((aws ssm get-parameter --name ${TAGPREFIX}-${HOSTNAME} | jq '.Parameter.Value') 2>&1)
    SGID=$((aws ec2 describe-instances --instance-ids ${INSTANCEID:1:-1} | jq '.Reservations[0].Instances[0].NetworkInterfaces[0].Groups[0].GroupId') 2>&1)
    INGRESSIP=$((aws ec2 describe-security-groups --group-ids ${SGID:1:-1} | jq '.SecurityGroups[0].IpPermissions[0].IpRanges[0].CidrIp') 2>&1)
    echo "[1/3]Revoking network ingress"
    TEMP=$((aws ec2 revoke-security-group-ingress --group-id ${SGID:1:-1} --protocol tcp --port 8443 --cidr ${INGRESSIP:1:-1}) 2>&1)
    TEMP=$((aws ec2 revoke-security-group-ingress --group-id ${SGID:1:-1} --protocol udp --port 8443 --cidr ${INGRESSIP:1:-1}) 2>&1)
    TEMP=$((aws ec2 stop-instances --instance-ids ${INSTANCEID:1:-1}) 2>&1)
    echo "[2/3]Stopping instance ${INSTANCEID:1:-1} (this might take a few minutes)..."
    aws ec2 wait instance-stopped --instance-ids ${INSTANCEID:1:-1}
    echo -e "${LIGHTBLUE}[3/3]Instance stopped and security group egress disabled.${ENDCOLOR}"
    ;;
    # =============================================================================
    # -delete --hostname ${HOSTNAME}
    # -----------------------------------------
  4)
    echo -e "${LIGHTGREEN}Deleting workstation and environment for user${LIGHTYELLOW} ${HOSTNAME} ${ENDCOLOR}"
    # =============================================================================
    INSTANCEPROFILENAME=gpicserverprofile-${HOSTNAME}
    INSTANCEROLENAME=gpicserverrole-${HOSTNAME}
    INSTANCEROLEPOLICY=gpicserverpolicy-${HOSTNAME}
    INSTANCEASSUMEROLEPOLICYDOCUMENT=gpicassumerolepolicy-${HOSTNAME}
    # =============================================================================
    VPCID=$((aws ec2 describe-vpcs --filters Name=cidr,Values=${VPCCIDR} Name=tag:Name,Values=${TAGPREFIX}-vpc | jq '.Vpcs[0].VpcId') 2>&1)
    IGWID=$((aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${VPCID:1:-1} | jq '.InternetGateways[].InternetGatewayId') 2>&1)
    PUBLICSUBNETA=$((aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPCID:1:-1} Name=cidr,Values=${VPCSUBNETPUBLICACIDR} | jq '.Subnets[0].SubnetId') 2>&1)
    PUBLICROUTETABLEA=$((aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=${PUBLICSUBNETA:1:-1} | jq '.RouteTables[0].Associations[0].RouteTableId') 2>&1)
    SGID=$((aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPCID:1:-1} Name=tag:Owner,Values=${HOSTNAME} | jq '.SecurityGroups[0].GroupId') 2>&1)
    INSTANCEID=$((aws ec2 describe-instances --filters Name=tag:Name,Values=${TAGPREFIX}-${HOSTNAME} Name=vpc-id,Values=${VPCID:1:-1} | jq '.Reservations[0].Instances[0].InstanceId') 2>&1)

    TEMP=$((aws ec2 terminate-instances --instance-ids ${INSTANCEID:1:-1}) 2>&1)
    echo "[1/3]Terminating instance"
    aws ec2 wait instance-terminated --instance-ids ${INSTANCEID:1:-1}
    INSTANCESTATUS=$((aws ec2 delete-security-group --group-id ${SGID:1:-1} | jq 'TerminatingInstances[0].CurrentState.Name') 2>&1)
    echo "[2/3]Instance and SG deleted"

    # Lots of detaching and deleting, when building it's Policies > Role > Instance Profile, so we work in reverse here.
    aws iam remove-role-from-instance-profile --instance-profile-name ${INSTANCEPROFILENAME} --role-name ${INSTANCEROLENAME}
    aws iam delete-instance-profile --instance-profile-name ${INSTANCEPROFILENAME}
    aws iam detach-role-policy --role-name ${INSTANCEROLENAME} --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
    aws iam detach-role-policy --role-name ${INSTANCEROLENAME} --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
    # You can get throttled on IAM delete operations, so we wait here
    sleep 3
    aws iam detach-role-policy --role-name ${INSTANCEROLENAME} --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${INSTANCEROLEPOLICY}
    aws iam delete-role --role-name ${INSTANCEROLENAME}
    aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${INSTANCEROLEPOLICY}
    echo "[3/3]Server instance role and profile deleted"

    aws ssm delete-parameter --name ${TAGPREFIX}-${HOSTNAME}
    echo -e "${LIGHTBLUE}Workstation resources for user${LIGHTYELLOW} ${HOSTNAME} ${LIGHTBLUE}deleted.${ENDCOLOR}"

    # Check to see if other instances exist in the VPC
    TEMP=$((aws ec2 describe-instances --filters "Name=vpc-id,Values=${VPCID:1:-1}" | jq '.Reservations[0].Instances[0]') 2>&1)
    if [ "${TEMP}" = "null" ]
    then
      echo -e "${LIGHTBLUE}No other workstations configured, deleting network environment${ENDCOLOR}"
      aws ec2 delete-subnet --subnet-id ${PUBLICSUBNETA:1:-1}
      echo "[1/5]Subnet deleted"
      aws ec2 delete-route-table --route-table-id ${PUBLICROUTETABLEA:1:-1}
      echo "[2/5]Route table deleted"
      aws ec2 detach-internet-gateway --internet-gateway-id ${IGWID:1:-1} --vpc-id ${VPCID:1:-1}
      echo "[3/5]IGW detached"
      aws ec2 delete-internet-gateway --internet-gateway-id ${IGWID:1:-1}
      echo "[4/5]IGW deleted"
      sleep 3
      aws ec2 delete-vpc --vpc-id ${VPCID:1:-1}
      echo "[5/5]VPC deleted"
      echo -e "${LIGHTBLUE}All demo resources deleted ${ENDCOLOR}"
    else
      echo -e "${LIGHTBLUE}Delete all configured workstations if you wish to also delete the network environment${ENDCOLOR}"
    fi
    ;;
    # =============================================================================
    # Demo environment workstation status
    # -----------------------------------------
  5)
    VPCID=$((aws ec2 describe-vpcs --filters Name=cidr,Values=${VPCCIDR} Name=tag:Name,Values=${TAGPREFIX}-vpc | jq '.Vpcs[0].VpcId') 2>&1)
    WSLIST=$((aws ec2 describe-instances --filters "Name=vpc-id,Values=${VPCID}" --query Reservations[*].Instances[*]) 2>&1)
    WSLENGTH=$((echo $WSLIST | jq '. | length') 2>&1)
    echo ""
    echo -e "${LIGHTYELLOW}Hostname - IPaddress - Status${ENDCOLOR}"
    for ((i = 0 ; i < $WSLENGTH ; i++))
    do
        TEMPITEM=$((echo $WSLIST | jq ".[$i]") 2>&1)
        TEMPITEM=${TEMPITEM:2:-2}
        WSHOST=$((echo $TEMPITEM | jq ".Tags[] | select(.Key | contains(\"Owner\")) | .Value") 2>&1)
        WSIPADDR=$((echo $TEMPITEM | jq ".PublicIpAddress") 2>&1)
        if [ "${WSIPADDR}" = "null" ]
        then
          WSIPADDR=" not available "
        fi
        WSSTATUS=$((echo $TEMPITEM | jq ".State.Name") 2>&1)
        echo -e "${LIGHTBLUE}${WSHOST:1:-1} - ${WSIPADDR:1:-1} - ${WSSTATUS:1:-1}${ENDCOLOR}"
    done
    echo ""
    ;;
    # =============================================================================
    # Help information
    # -----------------------------------------
  6)
    echo -e "${LIGHTBLUE}This script creates a network environment and configures a GPU instance for remote streaming"
    echo -e "Usage:"
    echo -e "Create workstation, will create network infrastructure to support the instance."
    echo -e "syntax: ${LIGHTCYAN}. ${SCRIPTNAME} -create --hostname ${LIGHTYELLOW}YOURHOSTNAME"
    echo -e "${LIGHTBLUE}Login to your workstation and set up security group rules to allow traffic from your IP address."
    echo -e "syntax: ${LIGHTCYAN}. ${SCRIPTNAME} -login --hostname ${LIGHTYELLOW}YOURHOSTNAME ${LIGHTCYAN}--ip ${LIGHTYELLOW}YOURIPADDRESS"
    echo -e "${LIGHTBLUE}Log off from your environment, will shut down the instance and remove the security group rules from your IP address."
    echo -e "syntax: ${LIGHTCYAN}. ${SCRIPTNAME} -logout --hostname ${LIGHTYELLOW}YOURHOSTNAME"
    echo -e "${LIGHTBLUE}Delete workstation and network infrastructure"
    echo -e "syntax: ${LIGHTCYAN}. ${SCRIPTNAME} -delete --hostname ${LIGHTYELLOW}YOURHOSTNAME ${ENDCOLOR}"
    echo -e "${LIGHTBLUE}Get the status of the workstations in the demo environment"
    echo -e "syntax: ${LIGHTCYAN}. ${SCRIPTNAME} -status${ENDCOLOR}"
    ;;
    # =============================================================================
    # Catchall for errors / unexpected output
    # -----------------------------------------
  *)
    echo -e "${LIGHTRED}Operation aborted.${ENDCOLOR}"
    ;;
esac
# =============================================================================
# IP format validation function
# -----------------
function valid_ip()
{
    local  ip=$1
    local  out=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        out=$?
    fi
    return $out
}
