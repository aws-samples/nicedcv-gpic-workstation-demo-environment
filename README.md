## GPIC - Remote Game Testing Environment with NICE DCV for 4K 60 FPS Streaming - Demo Environment
The nicedcv-workstation-demo-environment repository contains a script that allows to single-command deploy a working demo environment via AWS CloudShell to stream high-resolution and low-latency video from a G4dn instance using the QUIC UDP protocol from NICE DCV. The script leverages the latest EC2 AMI that packages NICE, registry optimizations and NVIDIA Gaming drivers. AWS Session Manager is used to provide ssh-less browser access to the instance for administration using your AWS role permissions and the script provides login and logout functionality to turn on/enable the virtual workstation and scoped-down security group when needed and turn off/disable them when not to save cost and to lock down access. The script supports multiple workstations in the same demo environment using different hostnames (limited by VPC/Subnet size and your accounts' on-demand G-instance service limits) and can be modified to add extra networking and storage capabilities (e.g. AWS Client VPN, FSx for WFS).

![Demo environment architecture](https://github.com/aws-samples/nicedcv-gpic-workstation-demo-environment/blob/4cbe55cf56cf83a18fafcef79a8cc555039aa800/nice-dcv-workstation-demo-environment_ARCH.png)


## Prerequisites
1. Select one of the following regions to run the demo environment (in the AWS console, make sure this region is selected, you'll want a region geographically close to you to reduce latency):
  * US East (N.Virginia)
  * US East (Ohio)
  * US West (Oregon)
  * Asia Pacific (Mumbai)
  * Asia Pacific (Sydney)
  * Asia Pacific (Tokyo)
  * Europe (Frankfurt)
  * Europe (Ireland)
2. Check to see if you have sufficiently high service limits to run the virtual workstation. In AWS Quotas, search for "Running On-Demand G instances" or use this [link](https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas/L-DB2E81BA) and select the region in which you wish to run the environment. To run the default instance you will need a quota value of at least 16 and you can request a quota increase if needed.

    ![EC2 G instance quotas](https://github.com/aws-samples/nicedcv-gpic-workstation-demo-environment/blob/44be49604a0c2cf114e5d1906ede7d3bc0d5e983/nice-dcv-workstation-demo-environment_SQ.png)

3. Make sure your IAM user/assumed role has `cloudshell:*` permissions. If you are using the [AdministratorAccess](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AdministratorAccess) or [PowerUserAccess](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/PowerUserAccess) managed policies, you will have these enabled automatically.
4. [Download and install the DCV Client](https://www.nice-dcv.com/) for your local workstation and ensure that TCP and UDP ports 8443 is not being blocked by your network or firewall settings.

## Setup
1. In the AWS Console, ensure you have the correct region selected and open AWS CloudShell (a terminal icon next to the righty of the search bar is a shortcut to the service)
2. Once the shell is live, click on **Actions > Upload File** and upload `nicedcv-gpic-workstation-demo-environment.sh`
3. Run the script with:
```
. nicedcv-gpic-workstation-demo-environment.sh -create --hostname YOURHOSTNAME
```
where `YOURHOSTNAME` is case-sensitive and will uniquely identify a workstation within this demo environment.

## Setting/Resetting workstation password
*This step is required the first time you set up a new workstation in the demo environment.*
1. In the AWS Console, navigate to EC2 and locate your instance. Check the box to it and click on **Connect**. In the next screen, with **Session Manager** selected, click on **Connect**.

    ![Accessing the workstation via Session Manager](https://github.com/aws-samples/nicedcv-gpic-workstation-demo-environment/blob/44be49604a0c2cf114e5d1906ede7d3bc0d5e983/nicedcv-workstation-demo-environment_EC2.png)

2. In the PS shell, type `net user Administrator "YOURPASSWORDINDOUBLEQUOTES"`
where `"YOURPASSWORDINDOUBLEQUOTES"` is a sufficiently complex password you will use to connect from your local workstation.
3. Once complete, you can click on **Terminate** to close the session.

    ![Changing your Windows password](https://github.com/aws-samples/nicedcv-gpic-workstation-demo-environment/blob/44be49604a0c2cf114e5d1906ede7d3bc0d5e983/nice-dcv-workstation-demo-environmnent_PS.png)

## Connecting to your workstation
1. In the AWS CloudShell console, type:
```
. nicedcv-gpic-workstation-demo-environment.sh -login --hostname YOURHOSTNAME --ip YOURIPADDRESS
```
where `YOURHOSTNAME` is the case-sensitive hostname you used to create the workstation

where `YOURIPADDRESS` is the public IP address of your local workstation in this format: `1.2.3.4`

This will start the workstation and dynamically create Security Group rules that allows network access to the specified workstation from your local host. The public IP address and hostname to use to remotely connect will be displayed.

2. On your local workstation, open the NICE DCV client application
3. In **Connection Settings > Protocol** ensure that QUIC is selected for TCP and UDP ports 8443.
4. Enter the workstation IP address, click **Connect**, enter the username(default: Administrator) and the password you configured then click on **Login**.

## Disconnecting from your workstation
1. In the remote workstation, save your work and close the NICE DCV client connection.
2. In the AWS CloudShell console, type:
```
. nicedcv-gpic-workstation-demo-environment.sh -logout --hostname YOURHOSTNAME
```
where `YOURHOSTNAME` is the case-sensitive hostname you used to create the workstation
This will shut down the workstation (data not stored on the attached volume will be lost) and delete the Security Group rules to isolate the instance.

## Getting the status of the workstations in your environment
In the AWS CloudShell console, type:
```
. nicedcv-gpic-workstation-demo-environment.sh -status
```

## Deleting your workstation / demo environment
1. Ensure you have backed-up data as required, this operation will permanently delete the instance and attached volume.
2. In the AWS CloudShell console, type:
```
. nicedcv-gpic-workstation-demo-environment.sh -delete --hostname YOURHOSTNAME
```
where `YOURHOSTNAME` is the case-sensitive hostname you used to create the workstation

If there are multiple workstations configured in the demo environment, only the workstation and its associated resources will be deleted. If this is the only/last workstation in the environment, the associated network resources will also be deleted.

## Cost Considerations
The main costs for this solution are for the instance and data transfer out charges (1.209$/hr and 0.09$/GB respectively in us-east-1). It is recommended to shut down instances when not in use via the `-logout` command. You can check the status of the workstations deployed in the demo environment using the `-status` command.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
