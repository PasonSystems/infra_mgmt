AWS-Blue-Green-Deployment-Terraform
Terraform Blue Green deployment with lambda

Steps: cd into Terraform2 folder to setup the infrastructure bring up all resources require for the blue green

Run terraform init

Run terraform apply

then, cd into Terraform3 folder. this is to where we have the LAMBDA function triggered by SNS

Run terraform init

Run terraform apply

Run aws sns publish --topic-arn arn:aws:sns:(enter your region):(enter you aws id):call-lambda-maybe --message "This is me"
This works perfectly immutable switching from blue to green.
