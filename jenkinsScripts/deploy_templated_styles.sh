#! /bin/bash

#TODO: parameters modification and help

set -e
set -u

origin_directory=""
destination_directory=""
mako_server_variable_value=""
mako_protocol_variable_value=""



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
  echo -e "-o \t the directory that contains the styles templates."
  echo -e "-d \t the directory where you will write your styles. The script will create it if it doesn't exist."
  echo -e "-s \t the url on which sources will be served."
  echo -e " -p \t the protocol used to connect to the server."
  echo -e "example usage \t: jenkinsScripts/deploy_templated_styles.sh -d \"/var/local/vectortiles/gl-styles\" -s \"vectortiles.geo.admin.ch\" -p \"https\" -o \"./styles\""
}

function cleanup {
  rm -rf "$venv_path" || :
}

getopts ":hd:p:s:o:" opt; do
  case ${opt} in
    h)
      usage
      exit
      ;;
    d)
      destination_directory=${OPTARG}
      ;;
    p)
      mako_protocol_variable_value=${OPTARG}
      ;;
    s)
      mako_server_variable_value=${OPTARG}
      ;;
    o)
      origin_directory=${OPTARG}
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 2
      ;;
  esac
done

SECONDS=0

trap cleanup SIGHUP SIGINT SIGTERM EXIT

# We pull the latest styles. Maybe it's not useful if it's in Jenkins and Jenkins take the latest config, but I'll leave it here for now.

venv_path=".venv"
pip_path="${venv_path}/bin/pip"
mako_path="${venv_path}/bin/mako-render"

virtualenv ${venv_path}
${pip_path} install Mako==1.0.7

echo "Starting to process styles"


shopt -s nullglob

for directory in "${origin_directory}"/* ; do
# we take the commits hash and timestamps and put them into two arrays 
  dirname=${directory##*/}
  base_path="${destination_directory}/${dirname}"
  mkdir -p "${base_path}/current"
  cp -Tr "${directory}/" "${base_path}/current/" || :
  ${mako_path} --var 'protocol'="${mako_protocol_variable_value}" --var 'servername'="${mako_server_variable_value}" "${directory}"/style.json > "${base_path}"/current/style.json
done

mkdir -p "${destination_directory}"/../json/
cp ./json_sources/*.json "${destination_directory}"/../json/

duration=$SECONDS
echo "Elapsed time: $((duration / 60)) minutes and $((duration % 60)) seconds."

