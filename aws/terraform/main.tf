provider "aws" {
    region = var.region
}

# 
# SSH key used to access the EC2 instances
#
resource "aws_key_pair" "dse_terra_ssh" {
    key_name = var.keyname
    public_key = file("${var.ssh_key_localpath}/${var.ssh_key_filename}.pub")

    tags = {
        Name         = "${var.tag_identifier}-dse_terra_ssh"
        Environment  = var.env 
   }
}
