#!/bin/bash

cd terraform

echo
echo "##################################"
echo "# calculate the terraform plan ..."
echo "##################################"
echo
terraform plan -out myplan
echo

echo -n "DO you want to apply the plan and continue (yes or no)? "
echo 
read yesno
if [[ "$yesno" == "yes" ]]; then
   echo
   echo "##################################"
   echo "# apply the terraform plan ..."
   echo "##################################"
   echo
   terraform apply myplan
fi

cd ..
