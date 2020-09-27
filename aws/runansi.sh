#!/bin/bash

cd ansible

echo
echo ">>>> Configure recommended OS/Kernel parameters for DSE nodes <<<<"
echo
ansible-playbook -i hosts osparm_change.yml --private-key=~/.ssh/id_rsa_aws -u ubuntu
echo

echo
echo ">>>> Setup DSE application cluster <<<<"
echo
ansible-playbook -i hosts dse_app_install.yml --private-key=~/.ssh/id_rsa_aws -u ubuntu
echo

echo
echo ">>>> Setup DSE OpsCenter cluster <<<<"
echo
ansible-playbook -i hosts opsc_and_dse_metrics_install.yml --private-key=~/.ssh/id_rsa_aws -u ubuntu

cd ..
