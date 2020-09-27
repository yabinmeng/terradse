#
# The local directory where the SSH key files are stored
#
variable "ssh_key_localpath" {
   default = "<local_ssh_key_file_folder>"
}

#
# The local private SSH key file name 
#
variable "ssh_key_filename" {
   default = "id_rsa_aws"
}

#
# AWS EC2 key-pair name
#
variable "keyname" {
   default = "dse-sshkey"
}

#
# Default AWS region
#
variable "region" {
   //default = "us-east-1"
   default = "us-east-2"
}

#
# Default OS image: Ubuntu
#
variable "ami_id" {
   # Ubuntu Server 16.04 LTS (HVM), SSD Volume Type
   // us-east-1
   #default = "ami-10547475"
   # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type (64-bit x86)
   // us-east-1
   //default = "ami-0bcc094591f354be2"
   // us-east-2
   default = "ami-0e82959d4ed12de3f"
}

#
# AWS resource tag identifier
#
variable "tag_identifier" {
   default = "ymtest"
} 

#
# Environment description
#
variable "env" {
   default = "automation_test"
}

#
# OpsCenter and DSE workload type string for
# - "OpsCenter server node"
# - "DSE metrics cluster node"
# - "DSE application cluster node - DC1"
# - "DSE application cluster node - DC2"
# NOTE: make sure the type string matches the "key" string
#       in variable "instance_count/instance_type" map
# 
variable "opsc_srv_type" {
   default = "opsc_srv"
}
variable "dse_metrics_type" {
   default = "dse_metrics"
}
variable "dse_app_dc1_type" {
   default = "dse_app_dc1"
}
variable "dse_app_dc2_type" {
   default = "dse_app_dc2"
}

variable "instance_count" {
   type = map
   default = {
      opsc_srv    = 1
      dse_metrics = 2
      dse_app_dc1 = 3
      dse_app_dc2 = 3
   }
}

variable "instance_type" {
   type = map
   default = {
      opsc_srv   =  "t2.2xlarge"  
      // t2.2xlarge is the minimal DSE requirement
      dse_metrics = "t2.2xlarge"
      dse_app_dc1 = "t2.2xlarge"
      dse_app_dc2 = "t2.2xlarge"
   }
}
