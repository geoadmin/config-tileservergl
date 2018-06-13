#!/bin/bash
#
# A simple script that should be placed at the root of the git containing the configurations.
# The goal is to pull the configurations, and then copy them via scp where they truly belong.
# Since it might be in a public repository, users and adresses are to be put as parameters rather than hard coded.
set -e



PATHTOROOT="/somewhere/over/the/rainbow"
EFS="nowhere"
USER="nobody"

function usage {
  echo "Usage:"
  echo
  echo "-h --help"
  echo -e "--path \t The path, inside the EFS, where we should store our styles"
  echo -e "--efs \t the address (IP or DNS) to the EFS in which you want to plug your styles. By default, it's nowhere."
  echo -e "--user \t the user that will copy to the EFS. By default, it's nobody."
  echo "No more help for you, it's not a hard script to use."
}

while [ "${1}" != "" ]; do
    PARAM=$(echo "${1}" | awk -F= '{print $1}')
    VALUE=$(echo "${1}" | awk -F= '{print $2}')
    case ${PARAM} in
        --help)
            usage
            exit
            ;;
        --env)
            PATHTOROOT=${VALUE}
            ;;
        --efs)
            EFS=${VALUE}
            ;;
        --user)
            USER=${VALUE}
            ;;
        *)
            echo "ERROR: unknown parameter \"${PARAM}\""
            usage
            exit 1
            ;;
    esac
    shift
done

echo "pulling the styles repository"
git pull

echo "copying to  $USER@$EFS:$PATHTOROOT"
scp -r ./fonts   "$USER@$EFS:$PATHTOROOT/fonts"
scp -r ./sprites "$USER@$EFS:$PATHTOROOT/sprites"
scp -r ./styles  "$USER@$EFS:$PATHTOROOT/styles"

