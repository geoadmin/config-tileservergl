#! /bin/bash

#TODO: parameters modification and help

set -e
set -u

MAKO_SERVER_VARIABLE_NAME="servername"
MAKO_PROTOCOL_VARIABLE_NAME="protocol"


environment="dev"
efs_instance="eu-west-1b.fs-da0ee213.efs.eu-west-1.amazonaws.com"
destination_directory="vib2d_tiles"
local_path_to_mount_point="/var/local"
mako_server_variable_value="vectortiles.geo.admin.ch"
mako_protocol_variable_value="https"


group="mockup_geodata"
user="mockup_geodata"

if [ "$(whoami)" != "root" ]; then
  (>&2 echo "Script must be run as root")
  exit -1
fi

if [ "$(type jq || :)" = "" ]; then
  (>&2 echo "jq not installed")
  exit -2
fi

function usage {
  echo "Usage:"
  echo
  echo "-h --help"
  echo -e "--efs \t the efs volume you wish to mount in read-write. [default: 'eu-west-1b.fs-da0ee213.efs.eu-west-1.amazonaws.com']"
  echo -e "--env \t the environment in which you're deploying [dev, int, prod]. [default: 'dev']" 
  echo -e "--path \t the local repository used as the base to  mount  the efs. [default: '/var/local']"
  echo -e "--dest \t the directory, both in efs and locally, that you're mounting [default: 'vib2d_tiles']"
  echo -e "example usage \t: updateStyle.sh --destination=\"\" --efs=\"[SERVER NAME]\" --path=\
         \"/var/anotherlocal\" --env=\"dev\" --dest=\"style_storage\""
}

function cleanup {
  rm -rf "$output_path" || :
  rm -rf "$venv_path" || :
  userdel "$user" || :
}


if [ $# -gt 0 ]; then
  while [ "${1:-}" != "" ]; do
    PARAM=$(echo "${1}" | awk -F= '{print $1}')
    VALUE=$(echo "${1}" | awk -F= '{print $2}')
    case ${PARAM} in
        --help)
            usage
            exit
            ;;
        --efs)
	    efs_host=${VALUE}
            ;;
	--env)
	    environment=${VALUE}
	    ;;
        --mnt)
            local_volume=${VALUE}
            ;;
        *)
            (>&2  echo "ERROR: unknown parameter \"${PARAM}\"")
            usage
            exit 1
            ;;
    esac
    shift
  done
fi

local_volume="${local_path_to_mount_point}/efs-${environment}/${destination_directory}"
efs_volume="${efs_instance}://${environment}/${destination_directory}"


SECONDS=0

trap cleanup SIGHUP SIGINT SIGTERM EXIT

# We pull the latest styles. Maybe it's not useful if it's in Jenkins and Jenkins take the latest config, but I'll leave it here for now.

venv_path=".venv"
pip_path="${venv_path}/bin/pip"
mako_path="${venv_path}/bin/mako-render"

virtualenv ${venv_path}
${pip_path} install Mako==1.0.7

groupadd "$group" -g 2500
useradd -u 2500 -g 2500 "$user"

output_path=$(sudo -u "$user" mktemp -d)


efs_is_mounted_to_local_volume=$(grep "$efs_volume $local_volume nfs4 rw" /proc/mounts || echo "")

efs_is_mounted=$(grep "$efs_volume" /proc/mounts | grep nfs4 | grep rw || echo "")

if [ ${#efs_is_mounted} -eq 0 ] ; then
  echo "mounting efs..."
  mount.nfs4 "$efs_volume" "$local_volume" -w
  echo "efs mounted"
elif [ ${#efs_is_mounted_to_local_volume} -eq 0 ] ; then
  (>&2 echo "error: efs is already mounted somewhere else. The local volume directive must be the mounting point of the efs or the efs should not be mounted on this device.")
  exit 2
fi

echo
echo "Starting to process styles"


shopt -s nullglob

for directory in styles/* ; do
# we take the commits hash and timestamps and put them into two arrays 
  dirname=${directory##*/}

  base_path="$output_path/styles/$dirname"
  mkdir -p "${base_path}/current"
  echo "${directory}"
  cp -Tr "${directory}/" "${base_path}/current/" || :
  ${mako_path} --var ${MAKO_PROTOCOL_VARIABLE_NAME}=${mako_protocol_variable_value} --var ${MAKO_SERVER_VARIABLE_NAME}=${mako_server_variable_value} "${directory}/style.json" > "${base_path}/current/style.json"

  ls ${base_path}/current
done

sudo -u "$user" mkdir -p "$local_volume"/json/
sudo -u "$user" cp "./json_sources/"*".json" "$local_volume"/json/

#rsync between the destination folder in the EFS and the local styles, font and sprites directory
echo "Starting to rsync"

sudo -u "$user" rsync -avzh "$output_path/" "$local_volume"

echo "Creating symlinks"
# for each style directory


duration=$SECONDS
echo "Elapsed time: $((duration / 60)) minutes and $((duration % 60)) seconds."

