
variable "availability_zones" {
  description = "A comma-delimited list of availability zones for the VPC."
  default = "us-west-2a,us-west-2b"
}

variable "ami" {
  default = "ami-07669fc90e6e6cc47"
}

variable "deployment_name"{
  default="Terraform-0downtime-BlueGreen"
}

variable "user_data_file_string"{
  default = "C:/Users/Default.Default-PC/Downloads/install_apache_server2.sh"
}

variable "min_asg" {
  default = 2
}

variable "max_asg" {
  default = 5
}

variable "ASG_health_check_grace"{
  default = 200
}

variable "ASG_health_check_type"{
  default="ELB"
}

variable "ASG_enabled_metrics" {
  default=["GroupInServiceInstances","GroupTotalInstances"]
}

variable "instance_type" {
  default = "t2.nano"
}

variable "always_switch" {
  default = false
}

variable "first_time_create" {
  default = false
}

locals {
 ASG1_is_active = tobool(chomp(file(".ASG1Active.txt")))
 old_user_data =  chomp(file(".UserData.txt"))
 old_ami =  chomp(file(".AMI.txt"))
 new_LC=local.old_user_data!=var.user_data_file_string||local.old_ami!=var.ami?true:false
 change_to_ASG_2=(var.always_switch==false&&local.ASG1_is_active==local.new_LC)||(var.always_switch&&local.ASG1_is_active)?true:false
 ASG1_max = local.change_to_ASG_2?0:var.max_asg
 ASG1_min = local.change_to_ASG_2?0:var.min_asg
 ASG2_max = local.change_to_ASG_2?var.max_asg:0
 ASG2_min = local.change_to_ASG_2?var.min_asg:0
}

output "old_raw_user_data" {
  value = local.old_user_data
}

output "new_raw_user_data" {
  value = var.user_data_file_string
}
output "ASG1Max" {
  value = local.ASG1_max
}
output "ASG1Min" {
  value = local.ASG1_min
}
output "ASG2Max" {
  value = local.ASG2_max
}
output "ASG2Min" {
  value = local.ASG2_min
}
output "always_switch" {
  value = var.always_switch
}
output "switch_due_to_data" {
  value = local.new_LC
}
output "ASG1_is_active" {
  value = local.ASG1_is_active
}
output "change_to_ASG2" {
  value = local.change_to_ASG_2
}
output "first_time_create" {
  value = var.first_time_create
}