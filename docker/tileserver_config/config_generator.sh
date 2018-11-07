#!/bin/bash
#
# Generate a config file for tileserver GL

#params are --env=dev|prod|int

set -eu

root_path=""
fonts_subpath=""
sprites_subpath=""
styles_subpath=""
tiles_subpath=""
IFS=',' read -r -a initial_boundaries <<<"180,90,-180,-90"

function usage {
  echo "Usage:"
  echo
  echo "-h --help"
  echo -e "--root \t define the base path tileserver will follow to find resources in /var/local/efs-\$env/ [default: vectortiles]."
  echo -e "--root must be set after --env. "
  echo -e "--fonts \t the path to the fonts from the root. [default: fonts]"
  echo -e "--sprites \t same as --fonts, but for sprites. [default: sprites]"
  echo -e "--tiles \t Where is the base of the mbtiles storage from the root. [default: swisstopo-tiles]"
  echo -e "--styles \t Where is the base of the styles storage from the root. [default: swisstopo-styles]"
}

function cleanup {
  rm -rf "$temporary_json_storage"
  exit
}

while [ "${1:-}" != "" ]; do
    PARAM=$(echo "${1}" | awk -F= '{print $1}')
    VALUE=$(echo "${1}" | awk -F= '{print $2}')
    case ${PARAM} in
        --help)
            usage
            exit
            ;;
        --root)
            root_path="${VALUE}"
            ;;
        --fonts)
            fonts_subpath=${VALUE}
            ;;
        --sprites)
            sprites_subpath=${VALUE}
            ;;
        --tiles)
            tiles_subpath=${VALUE}
            ;;
        --styles)
            styles_subpath=${VALUE}
            ;;
        *)
            echo "ERROR: unknown parameter \"${PARAM}\""
            usage
            exit 1
            ;;
    esac
    shift
done

SECONDS=0

temporary_json_storage=$(mktemp -d)
mkdir -p /usr/src/app

trap cleanup SIGHUP SIGINT SIGTERM EXIT

#STEP 1 : we write the "options" json

options_json="  \"options\":{\n\
    \"paths\":{\n\
      \"root\":\"$root_path\",\n\
      \"fonts\":\"$fonts_subpath\",\n\
      \"sprites\":\"$sprites_subpath\",\n\
      \"styles\":\"$styles_subpath\",\n\
      \"mbtiles\":\"$tiles_subpath\"\n\
      },\n\
    \"serveAllFonts\":true\n\
    },\n"

#STEP 2 : we write the 'data' json
data_json="  \"data\":{\n"

path_to_data="$root_path/$tiles_subpath"
let length_of_path=${#path_to_data}+1
for file in $path_to_data/*/*/tiles.mbtiles
do
  
  let length_of_file=${#file}-$length_of_path
  source_and_version=${file:$length_of_path:$length_of_file-14}

  echo ${source_and_version}
  
  data_json+="\
    \"${source_and_version}\":{\n\
      \"mbtiles\":\"${file:$length_of_path:$length_of_file}\"\n\
    },"

done
 data_json=${data_json:0:${#data_json}-1}

data_json+="\n  },\n"

#STEP 3: we write the 'style' json
styles_json="  \"styles\":{\n"
path_to_styles="$root_path/$styles_subpath"

let length_of_path=${#path_to_styles}+1
for file in $path_to_styles/*/*/style.json
do
  #now, we start to find the boundaries

#first, we extract the data sources of the styles. Since jq uses files as input, we store them
# in temporary files
  jq '.sources' "$file" > "$temporary_json_storage/sources.json"
  jq '.[]' "$temporary_json_storage/sources.json" > "$temporary_json_storage/insides.json"
  IFS=',' read -r -a boundaries <<< "180,90,-180,-90"

#We look through each "url" field in each source json and only take vectortiles into account. 
#Since vectortiles url are in the form "mbtiles://{mbtiles_id}", we pick only the id and we look
#For a tile file that is at the same location. 
#We then read the bounds value from the file and, if none are found or the file isn't found, 
#we return the reversed default value. At the end of these loops,
IFS=' '
urls=$(jq '.url' "$temporary_json_storage/insides.json")
while read -r  url 
do
  if [[ "$url" = *"mbtiles"* ]]
    then
      
      identifier="${url:12:${#url}-14}"
      echo "$identifier"
      
      IFS=',' read -r -a fetchedboundaries <<< $(sqlite3 "$path_to_data/$identifier/tiles.mbtiles" "SELECT value FROM metadata WHERE name= 'bounds';" || echo "180,90,-180,-90")
for index in "${!fetchedboundaries[@]}"
           do
             if [ "$index" -lt 2 ]
               then
                 if  (( $(echo "${fetchedboundaries[index]} < ${boundaries[index]}" | bc -l ) ))
                   then
                     boundaries[$index]=${fetchedboundaries[index]}
                 fi
             else
                 if  (( $(echo "${fetchedboundaries[index]} > ${boundaries[index]}" | bc -l ) ))
                  then
                     boundaries[$index]=${fetchedboundaries[index]}
                fi
             fi
           done
      for index in "${!boundaries[@]}"
      do
        if [ "${boundaries[index]}" = "${initial_boundaries[index]}" ]
          then
            if [ "$index" -lt 2 ]
             then
             boundaries[$index]="-${initial_boundaries[index]}"
            else
             boundaries[$index]="${initial_boundaries[index]:1}"
            fi
         fi
      done
  fi
done <<< $urls
IFS=','
bounds="[${boundaries[*]// /,}]"

  let length_of_file=${#file}-$length_of_path
  style_and_version=${file:$length_of_path:$length_of_file-11}
  echo 'style_and_version'

      styles_json+="    \"${style_and_version}\":{\n\
      \"style\":\"${file:$length_of_path:$length_of_file}\",\n\
      \"serve_rendered\":false,\n\
      \"serve_data\":true,\n\
      \"tilejson\":{\n\
        \"bounds\":$bounds\n\
      }\n\
    },"
  if [[ $file = *"current"* ]]
    then
      styles_json+="    \"${file:$length_of_path:$length_of_file-19}\":{\n\
      \"style\":\"${file:$length_of_path:$length_of_file}\",\n\
      \"serve_rendered\":false,\n\
      \"serve_data\":true,\n\
      \"tilejson\":{\n\
        \"bounds\":$bounds\n\
      }\n\
    },"
  fi

done
styles_json=${styles_json:0:${#styles_json}-1}
styles_json+="\n  }\n"

echo""
echo "$options_json"
echo ""
echo "$styles_json"
echo ""
echo "$data_json"
echo ""

echo -e "{\n$options_json$data_json$styles_json\n}" > app-config.json

duration=$SECONDS
echo "Elapsed time: $((duration / 60)) minutes and $((duration % 60)) seconds."

exit 0
