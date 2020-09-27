#!/bin/bash

cd terraform

TFSTATE_FILE=/tmp/tfshow.txt
terraform show terraform.tfstate > $TFSTATE_FILE

cd ..

dse_nodetypes=()
public_ips=()
private_ips=()

# print message to a file (appending)
# $1 - message
# $2 - file to append
pmsg() {
   echo "$1" >> $2
}

usage() {
   echo "Error: Only accepts a postivie number as the only (optional) input parameter"
   echo "-- usage: genansinv.sh [<number_of_seeds_per_dc>]"
}

# check if an input is a positive number
isnum() { 
   awk -v a="$1" 'BEGIN {print ((a == a + 0) && (a > 0)) }'; 
}

while IFS= read -r line
do
   if [[ $line == *"aws_instance."* ]]; then
      ## In ${line##*.}"
      ## - "*." matches a string followed by '.'
      ## - "##" drops the longest matching prefix
      ## - "#" drops the shortest matching prefix
      ##-----------------
      ## e.g. "typestr" is like "dse_app_dc1[0]:"
      typestr="${line##*.}"
      ## remove trailing ':' character
      typestr=$(echo "$typestr" | sed 's/\://g')

      ## replace '[' to '.' and remove ']'
      ##-----------------
      ## e.g. "typestr2" is like "dse_app_dc1.0"
      typestr2=$(echo "$typestr" | sed 's/\]//' | sed 's/\[/./')
       
      dse_nodetypes+=("$typestr2")
   fi

#echo "$line"
   if [[ $line == *"private_ip"* ]]; then
      ## exclude "secondary_private_ipss"
      if [[ $line != *"ips"* ]]; then
         prv_ip="${line##* = }"
         ## remove all occurence of character '#'
         prv_ip=$(echo $prv_ip | sed 's/\"//g')

         private_ips+=("$prv_ip")
      fi
   fi

   if [[ $line == *"public_ip"* ]]; then
   ## exclude "associate_public_ips_address"
      if [[ $line != *"address"* ]]; then
         pub_ip="${line##* = }"
         ## remove all occurence of character '#'
         pub_ip=$(echo $pub_ip | sed 's/\"//g')

         public_ips+=("$pub_ip")
      fi
   fi
done < $TFSTATE_FILE


# Generate an IP list file 
IPLIST_FILE="dse_ec2IpList"
publicIpCnt=${#public_ips[*]}

cat /dev/null > $IPLIST_FILE
for ((i=0; i<${#dse_nodetypes[*]}; i++));
do
    # in case there is no public IP available,
    #   we use private IP instead
    if [[ $publicIpCnt == 0 ]]; then
       public_ips[i]=${private_ips[i]}
    fi

    pmsg "${dse_nodetypes[i]},${public_ips[i]},${private_ips[i]}" $IPLIST_FILE
done

# default number of seeds per DC is 1
# this can be changed from the only input parameter of this command
SEED_PER_DC=1

if [[ "$1" != "" ]]; then
   res=`isnum "$1"`
   if [[ $# > 1 ]] || [[ "$res" != "1" ]] ; then
      usage
      exit 
   fi

   SEED_PER_DC="$1"
fi


DSE_APPCLUSTER_NAME="MyAppCluster"
DSE_OPSCCLUSTER_NAME="OpscCluster"


# Generate Ansible inventory file for multi-DC DSE cluster (no OpsCenter)
DSE_ANSINV_FILE="dse_ansHosts"

cat /dev/null > $DSE_ANSINV_FILE
pmsg "[dse_app:children]" $DSE_ANSINV_FILE
pmsg "dse_app_dc1" $DSE_ANSINV_FILE
pmsg "dse_app_dc2" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_app_dc1]" $DSE_ANSINV_FILE
seedmarked=0
for ((i=0; i<${#dse_nodetypes[*]}; i++));
do
   if [[ ${dse_nodetypes[i]} == *"dse_app_dc1"* ]]; then
      dc_name=$(echo "${dse_nodetypes[i]}" | cut -d'.' -f1 | cut -d'_' -f3 )

      if [[ $seedmarked < $SEED_PER_DC ]]; then
         pmsg "${public_ips[i]} private_ip=${private_ips[i]} seed=true dc=$dc_name rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         seedmarked=$((seedmarked+1))
      else
         pmsg "${public_ips[i]} private_ip=${private_ips[i]} seed=false dc=$dc_name rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_app_dc2]" $DSE_ANSINV_FILE
seedmarked=0
for ((i=0; i<${#dse_nodetypes[*]}; i++));
do
   if [[ ${dse_nodetypes[i]} == *"dse_app_dc2"* ]]; then
      dc_name=$(echo "${dse_nodetypes[i]}" | cut -d'.' -f1 | cut -d'_' -f3 )

      if [[ $seedmarked < $SEED_PER_DC ]]; then
         pmsg "${public_ips[i]} private_ips=${private_ips[i]} seed=true dc=$dc_name rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         seedmarked=$((seedmarked+1))
      else
         pmsg "${public_ips[i]} private_ip=${private_ips[i]} seed=false dc=$dc_name rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_app:vars]" $DSE_ANSINV_FILE
pmsg "cluster_name=$DSE_APPCLUSTER_NAME" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "[dse_app_dc1:vars]" $DSE_ANSINV_FILE
pmsg "solr_enabled=0" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "[dse_app_dc2:vars]" $DSE_ANSINV_FILE
pmsg "solr_enabled=1" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE


pmsg "[dse_metrics]" $DSE_ANSINV_FILE
opscsrvmarked=0
seedmarked=0
for ((i=0; i<${#dse_nodetypes[*]}; i++));
do
   if [[ ${dse_nodetypes[i]} == *"dse_metrics"* ]]; then
      if [[ $seedmarked < $SEED_PER_DC ]]; then
         pmsg "${public_ips[i]} private_ip=${private_ips[i]} seed=true dc=DC1 rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         seedmarked=$((seedmarked+1))
      else
         pmsg "${public_ips[i]} private_ip=${private_ips[i]} seed=false dc=DC1 rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_metrics:vars]" $DSE_ANSINV_FILE
pmsg "cluster_name=$DSE_OPSCCLUSTER_NAME" $DSE_ANSINV_FILE
pmsg "solr_enabled=0" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE



pmsg "[opsc_srv]" $DSE_ANSINV_FILE
opscSrvPrivateIP=''
for ((i=0; i<${#dse_nodetypes[*]}; i++));
do
   if [[ ${dse_nodetypes[i]} == *"opsc_srv"* ]]; then
      # only install OpsCenter server on one host
      if [[ $opscsrvmarked == 0 ]]; then
         opscSrvNodeStr="${public_ips[i]} private_ips=${private_ips[i]}" 
         opscSrvPrivateIp="${private_ips[i]}"
         opscsrvmarked=1
      fi
   fi
done
pmsg "$opscSrvNodeStr" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE



# Generate Ansible inventory file for datastax-agents
pmsg "[datastax_agent]" $DSE_ANSINV_FILE
for ((i=0; i<${#dse_nodetypes[*]}; i++));
do
   if [[ ${dse_nodetypes[i]} != *"opsc_srv"* ]]; then
      pmsg "${public_ips[i]} private_ips=${private_ips[i]} opsc_srv_ip=$opscSrvPrivateIp" $DSE_ANSINV_FILE
   fi
done
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE



pmsg "[osparmchg:children]" $DSE_ANSINV_FILE
pmsg "dse_app" $DSE_ANSINV_FILE
pmsg "dse_metrics" $DSE_ANSINV_FILE


# Copy the generated ansible inventory file to the proper place
cp $DSE_ANSINV_FILE ./ansible/hosts


# Delete intermediate files
rm $DSE_ANSINV_FILE
rm $IPLIST_FILE
