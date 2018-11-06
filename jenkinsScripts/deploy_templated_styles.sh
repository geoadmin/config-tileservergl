#! /bin/bash

#TODO: parameters modification and help

set -e
set -u


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
  echo -e "--dest \t the directory where you will write your styles. The script will create it if it doesn't exist."
  echo -e "--serverurl \t the url on which sources will be served."
  echo -e "--protocol \t the protocol used to connect to the server."
  echo -e "example usage \t: deploy_templated_styles.sh --dest=\"/var/local/vectortiles/gl-styles\" --serverurl=\"vectortiles.geo.admin.ch\" --protocol=\"https\""
}

function cleanup {
  rm -rf "$venv_path" || :
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
        --dest)
            destination_directory=${VALUE}
            ;;
        --protocol)
            mako_protocol_variable_value=${VALUE}
            ;;
        --serverurl)
            mako_server_variable_value==${VALUE}
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

for directory in styles/* ; do
# we take the commits hash and timestamps and put them into two arrays 
  dirname=${directory##*/}
  base_path="$destination_directory/$dirname"
  mkdir -p "${base_path}/current"
  cp -Tr "${directory}/" "${base_path}/current/" || :
  ${mako_path} --var 'protocol'="${mako_protocol_variable_value}" --var 'servername'="${mako_server_variable_value}" "${directory}"/style.json > "${base_path}"/current/style.json
done

mkdir -p "$destination_directory"/json/
cp "./json_sources/"*.json "$destination_directory"/json/

duration=$SECONDS
echo "Elapsed time: $((duration / 60)) minutes and $((duration % 60)) seconds."

