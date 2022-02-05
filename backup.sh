#!/bin/bash

# backupname is $Databasename_$TIMESTAMP
BACKUP_LOCATION="/home/backup/influx"
TIMESTAMP=$(date +'%Y%m%d%H')

#mongodb host
#make sure to set bind-address = ":8088" in the influxdb config to allow remotebackups if you are not using localhost
INFLUXHOST="loaclhost"
INFLUXPORT=8088

# databases to backup
# use all or specify but not both
BACKUP_ALL=true
DATABASES_TO_EXCLUDE=("_internal");
# or specify some databases here
DATABASES_TO_BACKUP=();

# docker container
DOCKER_NAME="influxbackup"

#check if only one option is used (all dbs or specified)
if [ ${#DATABASES_TO_BACKUP[@]} -gt 0 -a ${BACKUP_ALL} = true ] ; then
 echo "you can not use BACKUP_ALL=true and DATABASES_TO_BACKUP at the same time!"
 echo "set BACKUP_ALL to false or empty DATABASES_TO_BACKUP"
 exit
fi

#get latest docker image for influxdb
docker pull --quiet influxdb

#create container with given name if it does not exist
[[ $(docker ps -f "name=${DOCKER_NAME}" --format '{{.Names}}') == "${DOCKER_NAME}" ]] ||
docker run -d --name "${DOCKER_NAME}" -v ${BACKUP_LOCATION}:/data influxdb

# get all databases from influxdb
if [ ${BACKUP_ALL} = true ] ; then
  dbnamesstart=false;
  while read line; do
	# find start of dbnames
    if [ "${line}" = "----" ] ; then
	  dbnamesstart=true;
	  continue;	
	fi
	# skip other info
	if [ ${dbnamesstart} = false ] ; then
	  continue;
	fi

    if [[ ! " ${DATABASES_TO_EXCLUDE[@]} " =~ "${line}" ]]; then
      DATABASES_TO_BACKUP+=($line)
    fi
  done <<< $(docker exec ${DOCKER_NAME} echo SHOW DATABASES | influx)
fi

echo ${DATABASES_TO_BACKUP[@]}


# backup all filtered databases
for databasename in "${DATABASES_TO_BACKUP[@]}"
do
  :
  echo "backup for ${databasename}"
  docker exec ${DOCKER_NAME} influxd backup -portable -database ${databasename} -host "${INFLUXHOST}:${INFLUXPORT}" "/data/${databasename}"
  tar cfz "${BACKUP_LOCATION}${databasename}${TIMESTAMP}.tar.gz" -C "${BACKUP_LOCATION}" "${databasename}"
  rm -rf "${BACKUP_LOCATION}${databasename}"
done
