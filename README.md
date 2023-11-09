# Removing Computers from Managed AD Serverless

# Summary

When you create EC2 instances that will be joined to a Directory Service domain directory, AWS does this automatically by configuring a configuration in the AWS Console when launching the instance. However, to configure and administer these domains, excluding these machines from the domain when the EC2 instance is deleted, for example, you need to do this using compute services that you can directly interact with AD. This means that it is necessary to connect to instances that are part of this domain to perform all administrator tasks, as there are no cloud-native services to do this.

This pattern represents a serverless solution to be able to handle deletions of EC2 instances and automatically remove their reference within managed AD . This pattern creates an AWS Lambda that needs to be in the same virtual private cloud (VPC) as the AWS Managed AD and the instances that are part of the solution. It also creates an Amazon EventBridge Rule that sends events when an EC2 instance changes its state to “Terminated”, sending its instance-id as a parameter that will be consumed by AWS Lambda.
The sample code uses Python 3.8 with its dependencies to launch AWS Lambda function and uses Terraform to deploy and check for all cloud resources needed to the solution, looking for credentials used in AWS CLI to maintain good security practices.

# Prerequisites and limitations

## Prerequisites

* An active AWS account
* AWS CLI installed and ready to use, with a profile already configured and linked to an AWS account
* Python3 installed
* Terraforminstalled
* Git installed
* AWS Lambda will act on terminated EC2 instances, looking for the existence of a "hostname" tag containing the value of the computer name that the Active Directory recognizes for that instance.

Limitations

* AWS Lambda has a maximum function timeout of 15 minutes per AWS Lambda Quotas. Any operation must be completed with 15 minutes.

## Product versions

* Python 3.8 (you can use newer versions but needs to download its dependencies accordingly)
* Python boto3 Library 
* AWS CLI v2
* Terraform >= 0.12.0

# Architecture

## Target technology stack

AWS Directory Service, AWS Managed Microsoft AD, AWS Lambda, Amazon EventBridge, Amazon Virtual Private Cloud, AWS Secrets Manager.

## Target architecture

The diagram shows the following:
![alt text](./img/adcleanup.png?raw=true "Architecture Stack")
* A single Lambda function deployed in a private subnet that will stablish connection with Managed AD and AWS API Calls using a Route Table pointing to a NAT Gateway
* AWS Secrets Manager for storing sensitive information, like AD credentials, used by the Lambda function
* Amazon S3 bucket for storing the Lambda code
* Amazon CloudWatch Logs for storing the output of the the Lambda function
* AWS KMS providing encryption keys for Secrets Manager, CloudWatch Logs, and Lambda environment variables
* Amazon EventBridge triggers the Lambda function with a defined rule

## Automation and scale

Thanks to the serverless nature of our target technology stack, scaling is handled by AWS automatically. That being said, be mindful of AWS Service Quotas and request quota increases if you are going to realize concurrent executions in the deployed Lambda.

# Tools and Resources

## Tools

* AWS Lambda – Run code with no servers to manage and pay only for the compute time you use.
* AWS CLI – unified tool to manage your AWS services. With just one tool to download and configure, you can control multiple AWS services from the command line and automate them through scripts.
* Amazon VPC – Enable you to define and launch AWS resources in a logically isolated virtual network in AWS Cloud.
* AWS Secrets Manager – Manage, retrieve, and rotate database credentials, API keys, and other secrets throughout their lifecycles.
* Terraform - An open source infrastructure as code (IaC) software tool that allows DevOps engineers to programmatically provision the physical resources that an application requires to run.

## Code Repository

This Git repository contains the complete sample code. We will explain key concepts of this pattern through the code snippets below.


## Best practices

The following are some best practices for working with Lambda functions. Additional best practices and more information can found in the Lambda documentation.

* Use environment variables to pass operational parameters to your function. This allows updates to be made to the variables without requiring code modifications.
* Minimize your deployment package size to its runtime necessities. This will reduce the amount of time that it takes for your deployment package to be downloaded and unpacked ahead of invocation.
* Use most-restrictive permissions when setting IAM policies. Understand the resources and operations your Lambda function needs, and limit the execution role to these permissions.

## Infrastructure

All infrastructure is deployed via Terraform and AWS CLI.


## Lambda function

Lambda is responsible for get the instance-id from event, and use AWS API Calls to get the "Hostname" tag value from the EC2 instance, getting the machine name that is referred to in Active Directory. Then, Lambda consults in AWS Secrets Manager to get the AD Administrator Credentials, necessary to be able to clean the hostname reference. Afterwards, this program stablish a connection with AD using LDAP library, searching for the computer object inside the Domain and cleaning it's reference.

# Epics

## Deploy Infrastructure
* Initialize Terraform	
- Navigate to the root of the repository and using the Terraform CLI, run terraform init, followed by terraform plan to see the proposed deployment.	

* Deploy resources	
- Using the Terraform CLI, run terraform apply to deploy the AWS Lambda aligned with VPC configuration, Microsoft Managed AD with administrator access stored in Secrets Manager, and Amazon EventBridge with the corresponding configuration.	

## Test Solution
* Invoke the Lambda Function with a sample message	
- You can invoke the lambda with the command below: aws lambda invoke --function-name remove-computer-ad-function --cli-binary-format raw-in-base64-out --payload '{""detail"": {""instance-id"": ""example-id""}}' response.json	

## Verify the log in CloudWatch	
* Go to CloudWatch, select the Log Group named /aws/lambda/remove-computer-ad-function*, then open the latest log stream. 
- One of the log events contains the message payload.	

## Clean Up Infrastructure

* Delete the stack	
- terraform destroy	

* Answer The Prompt	
- Answer yes to confirm the deletion.	

# Author
The project/solution was made by Leonardo Bonato Bizaro. You can make contact using the following email: leonardobonatob@gmail.com