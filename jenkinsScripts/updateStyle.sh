#! /bin/bash
#
# The goal is to pull the configurations, and then copy them via scp and/or rsync where they truly belong.
# Since it might be in a public repository, users and adresses are to be put as parameters rather than hard coded.
set -e
set -u


git_path="."
destination_path=""
efs_volume=""
efs_server=""
efs_host=""
environment="dev"
local_volume=""
mbtiles_location="mbtiles"
fonts_update=0
group="mockup_geodata"
user="mockup_geodata"
target_hostname="tileserver.dev.bgdi.ch"
possible_hostname=("tileserver.dev.bgdi.ch" "tileserver.int.bgdi.ch" "vectortiles.geo.admin.ch")

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
  echo -e "--mbtiles \t The directory containing the sources files used in scripts"
  echo -e "--git \t The local git repository where your styles are stored. [default: .]"
  echo -e "--destination \t The path  where our configuration is supposed to end up inside the efs volume.[default:'']"
  echo -e "--efs \t the efs volume you wish to mount in read-write. [default: '']"
  echo -e "--env \t the environment in which you're deploying [dev, int, prod]. [default: 'dev']" 
  echo -e "--mnt \t the local repository used as a mount point for the efs. [default: '']"
  echo -e "\t we suggest including the environment in the local volume name too."
  echo -e "--fonts \t as the fonts syncing is a time consuming operation, it is \
disabled by default. the --fonts flag will tell the script upload the fonts, which \
will make the script run for a much longer time and you will cry when it happens. \
To be called when new fonts are pushed, or when you push the content to a whole new directory"
  echo -e "example usage \t: updateStyle.sh --destination=\"temp\" --efs=\"[SERVER NAME]\" --mnt=\
         \"/var/local/vectortiles\" --env=\"int\""
}

function cleanup {
  rm -rf "$output_path" || :
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
        --git)
            git_path=${VALUE}
            ;;
        --mbtiles)
            mbtiles_location=${VALUE}
            ;;
        --destination)
            destination_path=${VALUE}
            ;;
        --efs)
	    efs_host=${VALUE}
            ;;
	--env)
	    environment=${VALUE}
	    if [ ${VALUE} = 'int' ] ; then
		target_hostname="tileserver.int.bgdi.ch"
	    elif [ ${VALUE} = 'prod' ] ; then
		target_hostname="vectortiles.geo.admin.ch"
	    fi
		echo ${target_hostname}
	    ;;
        --mnt)
            local_volume=${VALUE}
            ;;
        --fonts)
            fonts_update=1
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
git -C "$git_path" pull

groupadd "$group" -g 2500
useradd -u 2500 -g 2500 "$user"

let git_path_length=${#git_path}
#styles in correct files.
#  
# We look through each json file at the root of styles and extract the historic of their commits
# As well as the associated timestamps. We will then loop through those arrays (only arrays 
# allow to loop on two at the same times, thanks to identic indices) to create the necessary files

output_path=$(sudo -u "$user" mktemp -d)

# We make sure the efs is mounted or we mount it.

efs_volume="${efs_host}://${environment}/vectortiles"



efs_is_mounted_to_local_volume=$(grep "$efs_volume $local_volume nfs4 rw" /proc/mounts || echo "")

efs_is_mounted=$(grep "$efs_volume" /proc/mounts | grep nfs4 | grep rw || echo "")

if [ ${#efs_is_mounted} -eq 0 ] ; then
  echo "mounting efs..."
  sudo -u "$user" mkdir -p "$local_volume"
  mount.nfs4 "$efs_volume" "$local_volume" -w
  echo "efs mounted"
elif [ ${#efs_is_mounted_to_local_volume} -eq 0 ] ; then
  (>&2 echo "error: efs is already mounted somewhere else. The local volume directive must be the mounting point of the efs or the efs should not be mounted on this device.")
  exit 2
fi

sudo -u "$user" mkdir -p "$local_volume/$destination_path"
tiles_path="$local_volume/$mbtiles_location"
echo
echo "Starting to process styles"


shopt -s nullglob

for directory in "$git_path"/styles/* ; do
# we take the commits hash and timestamps and put them into two arrays 
  IFS='  
' 
  read -r -a commit <<< $(git -C "$git_path" log --pretty=format:%H -- "$directory")
  read -r -a time <<< $(git -C "$git_path" log --pretty=format:%at -- "$directory")
  dirname=${directory##*/}

  base_path="$output_path/styles/$dirname"

  for index in "${!commit[@]}" ; do
    # The path to the specific version of the style is created. the UNIX timestamp is first
    # to allow ordering if needed. If there is already a directory created, we don't 
    # operate on this version and shifts to the next : the file already exists and 
    # doesn't need to be written over.
    version_path="$base_path/${time[index]}_${commit[index]}"
    if [ ! -d "$version_path" ] ; then
      sudo -u "$user" mkdir -p "$version_path"
      IFS=' '
      # The git show commit:FILE  command returns the content of the file as it was 
      # during the specified commit. We store that in a json. 
      versionned_files=$(git -C "$git_path" show "${commit[index]}":"${directory:$git_path_length+1}" | grep '.png\|.json' || echo "")
      if [[ ! $versionned_files = "" ]] ; then
        while read -r line ; do
          git -C "$git_path" show "${commit[index]}:$directory/$line"> "$version_path/$line" || echo  ""
        done <<< $versionned_files


        version="${time[index]}_${commit[index]}"
        style="$version_path/style.json"
        style_name="$dirname/$version"
        IFS=$'\n'
        sources_id=($(jq '.sources' "$style" | grep ": {" | grep -o -E '\w.+\w'))
        sources_url=($(jq '.sources' "$style" | jq '.[]' | jq '.url'))
        layers_sources_id=($(jq '.layers' "$style" | jq '.[]' | jq '.source' | grep -v null | grep -o -E '\w.+\w'))

        validate=0
        for url in "${sources_url[@]}" ; do
          if [[ $validate = 0 ]] ; then
            protocol="${url%://*}"
            protocol="${protocol:1}"
            if [[ "$protocol" = "mbtiles" ]]; then
              url_id="${url#*://}"
              url_id="${url_id:1:${#url_id} - 3}"
              src_id="${url_id%_*}"
              src_v="${url_id##*_}"
              if [[ ! -d "$tiles_path/$src_id/$src_v" ]] && [[ ! -L "$tiles_path/$src_id/$src_v" ]]; then
                (>&2 echo "unknown mbtiles id : $url_id")
                validate=1
              fi
            elif [[ "$protocol" = "local" ]] ; then
              file_id="${url#*://tilejson/}"
              file_id=${file_id:0:${#file_id} - 1}
              if [[ ! -f "$tiles_path/$file_id" ]]; then
                validate=1
                (>&2 echo "no local file $file_id")
              fi
            elif [[ ! "$protocol" = "http" ]] && [[ ! "$protocol" = "https" ]] ; then
              validate=1
              (>&2 echo "not a valid source type : $protocol")
            fi
          fi
        done
        for layer_source_id in "${layers_sources_id[@]}"; do
          if [[ $validate = 0 ]] ; then
            if [[ "${sources_id[@]}" = "${sources_id[@]#${layer_source_id}}" ]]; then
               validate=1
               (>&2 echo "layer source not corresponding to a source id : ${layer_source_id}")
            fi
          fi
        done  
        echo "$style_name validation : $validate"
        if [[ "${validate}" = 0 ]] ; then
          echo -e "\033[0;36m$style_name has all needed sources\033[0m"
        else
          (>&2 echo -e "\033[0;31mERROR : $style_name is either trying to use a non present source, or has a incorrectly specified source id in its layer.\033[0m")
          rm -rf "$version_path" || :
        fi
      else
        rm -rf "$version_path" || :
      fi
    fi 
    # IF NOTHING : OUT
    if [[ $(ls "$base_path") = "" ]] ; then
      rm -rf "$base_path" || :
      (>&2 echo -e "\033[1;31mERROR : Not a single good version for $dirname\033[0m")
    fi
  done
done

# for fonts, we are going for a recursive update copy. It will be faster than a copy and only overwrites more recent files rather than copying everything.
if [[ "${fonts_update}" = 1 ]] ; then
  echo "fonts update required. Copying fonts to temporary folder"
  sudo -u "$user" cp -r -u "$git_path/fonts" "$output_path/fonts"
fi
sudo -u "$user" mkdir -p "$local_volume/$destination_path/sprites"
sudo -u "$user" mkdir -p "$local_volume"/"$destination_path"json/
sudo -u "$user" cp "$git_path/json_sources/"*".json" "$local_volume"/"$destination_path"json/

#we replace the hostname by the appropriate one depending on the environment.
for target in ${possible_hostname[*]}; do
  find "$output_path/" -type f -exec sed -i "s/${target}/${target_hostname}/g" {} \;
done

#rsync between the destination folder in the EFS and the local styles, font and sprites directory
echo "Starting to rsync"

sudo -u "$user" rsync -avzh "$output_path/" "$local_volume/$destination_path"

echo "Creating symlinks"
# for each style directory


IFS=$'\n'
for directory in "$local_volume/$destination_path"/styles/*/ ; do
  if [ -d "$directory" ] ; then
    #we find the directory with the highest timestamp inside this one
    current_version=$(find "$directory" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort -r | sed -n 1p)
    if [ -L "$directory"current ] ; then
      sudo -u "$user" ln -srfn "$directory""$current_version" "$directory"current
    else   
      sudo -u "$user" ln -srf "$directory""$current_version" "$directory"current
    fi
  fi
done
duration=$SECONDS
echo "Elapsed time: $((duration / 60)) minutes and $((duration % 60)) seconds."

