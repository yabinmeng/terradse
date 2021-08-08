#
# EC2 instances for OpsCenter sever
#
resource "aws_instance" "opsc_srv" {
   ami            = var.ami_id
   instance_type  = lookup(var.instance_type, var.opsc_srv_type)
   count          = lookup(var.instance_count, var.opsc_srv_type)
   key_name       = aws_key_pair.dse_terra_ssh.key_name
   subnet_id      = aws_subnet.sn_dse_opsc.id

   vpc_security_group_ids = [
      aws_security_group.sg_internal_only.id,
      aws_security_group.sg_ssh.id,
      aws_security_group.sg_opsc_web.id,
      aws_security_group.sg_opsc_node.id
   ]

   tags = {
      Name         = "${var.tag_identifier}-${var.opsc_srv_type}-${count.index}"
      Environment  = var.env 
   }

   user_data = data.template_file.user_data.rendered
}


#
# EC2 instances for DSE metrics cluster
#
resource "aws_instance" "dse_metrics" {
   ami            = var.ami_id
   instance_type  = lookup(var.instance_type, var.dse_metrics_type)
   count          = lookup(var.instance_count, var.dse_metrics_type)
   key_name       = aws_key_pair.dse_terra_ssh.key_name
   subnet_id      = aws_subnet.sn_dse_cassmetr.id

   vpc_security_group_ids = [
      aws_security_group.sg_internal_only.id,
      aws_security_group.sg_ssh.id,
      aws_security_group.sg_dse_node.id
   ]

   tags = {
      Name         = "${var.tag_identifier}-${var.dse_metrics_type}-${count.index}"
      Environment  = var.env 
   }

   user_data = data.template_file.user_data.rendered
}

#
# EC2 instances for DSE application cluster, DC1
# 
resource "aws_instance" "dse_app_dc1" {
   ami            = var.ami_id
   instance_type  = lookup(var.instance_type, var.dse_app_dc1_type)
   count          = lookup(var.instance_count, var.dse_app_dc1_type)
   key_name       = aws_key_pair.dse_terra_ssh.key_name
   subnet_id      = aws_subnet.sn_dse_cassapp.id

   vpc_security_group_ids = [
      aws_security_group.sg_internal_only.id,
      aws_security_group.sg_ssh.id,
      aws_security_group.sg_dse_node.id
   ]

   tags = {
      Name         = "${var.tag_identifier}-${var.dse_app_dc1_type}-${count.index}"
      Environment  = var.env 
   }  

   user_data = data.template_file.user_data.rendered
}

#
# EC2 instances for DSE application cluster, DC 2
# 
resource "aws_instance" "dse_app_dc2" {
   ami            = var.ami_id
   instance_type  = lookup(var.instance_type, var.dse_app_dc2_type)
   count          = lookup(var.instance_count, var.dse_app_dc2_type)
   key_name       = aws_key_pair.dse_terra_ssh.key_name
   subnet_id      = aws_subnet.sn_dse_solrspark.id

   vpc_security_group_ids = [
      aws_security_group.sg_internal_only.id,
      aws_security_group.sg_ssh.id,
      aws_security_group.sg_dse_node.id
   ]

   tags = {
      Name         = "${var.tag_identifier}-${var.dse_app_dc2_type}-${count.index}"
      Environment  = var.env 
   }  

   user_data = data.template_file.user_data.rendered
}

data "template_file" "user_data" {
   template = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install python-minimal -y
              apt-get install ntp -y
              apt-get install ntpstat -y
              ntpq -pcrv
              EOF
}