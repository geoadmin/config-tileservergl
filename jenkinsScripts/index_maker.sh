#! /bin/bash

set -eu

resource_dir=""
resource_type=""
function usage {
  echo "Usage:"
  echo
  echo "-h  : show you this output here."
  echo -e "-d \t : the directory where you want to put your index in the efs."
  echo -e "-t \t : the type of resource you're looking for (style or mbtiles)"
  echo -e "-f \t : the directory where your resources are stored."
  echo -e "-s \t : the user:server parameters for the scp command"
  echo -e "example usage \t: jenkinsScripts/index_maker.sh -d \"/var/local/efs-dev/vectortiles/styles\" -t \"style\" -f \"/var/local/efs-dev/vectortiles/styles\" -s \"geodata@geodatasync\""
}

while getopts :ht:d:s:f: opt "$@";do
  case ${opt} in
    h)
      usage
      exit
      ;;
    t)
      resource_type=${OPTARG}
      ;;
    f)
      resource_dir=${OPTARG}
      ;;
    d)
      output_path=${OPTARG}
      ;;
    s)
      scp_parameters=${OPTARG}
      ;;
    \?)
      echo "invalid option : -${OPTARG}" >&2
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument" >&2
      exit 2
      ;;
  esac
done

#TODO : check what this does exactly and generate a correct index, with the correct rights in the correct place.
index="./index.html"
title=""
case ${resource_type} in
  style)
  title="List of Gl Styles"
  title_fr=""
  title_de=""
  resource="style.json"
  ;;
  mbtiles)
  title="List of Map Box Tiles Datasets"
  title_fr=""
  title_de=""
  resource="tiles.mbtiles"
  ;;
  *)
  (>&2 echo "ERROR: UNSUPPORTED RESOURCE TYPE \"${resource_type}\"")
  exit 2
  ;;
esac


function cleanup {
  rm ${index}
} 

trap cleanup SIGHUP SIGINT SIGTERM EXIT


echo "<!DOCTYPE html>" >${index}
echo "" >>${index}
echo "<head>" >>${index}
echo "  <meta charset=\"utf-8\">" >>${index}
echo "  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=\$start\">" >>${index}
echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" >>${index}
echo "  <title>Vector Tiles Styles</title>" >>${index}
echo "" >>${index}
echo "  <link rel=\"stylesheet\" href=\"/files/css/vendors.css\">" >>${index}
echo "  <link rel=\"stylesheet\" href=\"/files/css/admin1.css\">" >>${index}
echo "  <link rel=\"stylesheet\" href=\"/files/css/print.css\">" >>${index}
echo "" >>${index}
echo "</head>" >>${index}
echo "" >>${index}
echo "<body>" >>${index}
echo "  <div class=\"container container-main\">" >>${index}
echo "" >>${index}
echo "    <header>" >>${index}
echo "        <div class=\"clearfix\">" >>${index}
echo "          <section class=\"nav-services clearfix\">" >>${index}
echo "            <nav class=\"nav-lang\">" >>${index}
echo "              <ul>" >>${index}
echo "              </ul>" >>${index}
echo "            </nav>" >>${index}
echo "          </section>" >>${index}
echo "        </div>" >>${index}
echo "        <a href=\"#\" class=\"brand hidden-xs\" title=\"back to home\">" >>${index}
echo "          <img src=\"/files/img/logo-CH.png\" alt=\"back to home\" />" >>${index}
echo "          <h1>${title}<h1>" >>${index}
echo "        </a>" >>${index}
echo "    </header>" >>${index}
echo "" >>${index}
echo "          <nav class=\"nav-main yamm navbar\" id=\"main-navigation\"></nav>" >>${index}
echo "    <div class=\"container-fluid\">" >>${index}
echo "      <div class=\"row\">" >>${index}
echo "                  <div class=\"col-sm-4 col-md-3 drilldown\">" >>${index}
echo "            <a href=\"#collapseSubNav\" data-toggle=\"collapse\" class=\"collapsed visible-xs\">Sub-Navi" >>${index}
echo "            <div class=\"drilldown-container\">" >>${index}
echo "            </div>" >>${index}
echo "          </div>" >>${index}
echo "                <div class=\"col-sm-8 col-md-9\" id=\"content\">" >>${index}
echo "          <div class=\"row\">" >>${index}
echo "                <div class=\"col-sm-12\">" >>${index}
echo "<!-- MAIN CONTENT START--> " >>${index}
echo "" >>${index}
echo "<h1>List of available styles</h1>" >>${index}
echo "  <div id=\"navigation\" style=\"margin-bottom:14px;\"></div>" >>${index}
echo "  <div id=\"listing\">" >>${index}
echo "    <ul>" >>${index}


dirname="${resource_dir##*/}"


for jsonfile in "${resource_dir}"/*/*/${resource} ; do
  if [ -f "${jsonfile}" ]; then
    let length_of_filename=${#resource_type}
    let length_of_filename+=6   
    relative_url="${jsonfile:${#resource_dir}}"
    let rel_url_length=${#relative_url}
    let rel_url_length-=${length_of_filename}
    relative_url=${relative_url:0:${rel_url_length}-1}
    if  [ ${resource} = "style.json" ]; then
      style_name=$(jq '.name' ${jsonfile})
      echo "      <li>" >> ${index} 
      echo "      <a>${style_name}</a> <a href=\"/${dirname}${relative_url}/${resource_type}.json\">JSON</a>   <a href=\"/${dirname}${relative_url}/?vector\">VIEWER</a>" >> ${index}
    else
      echo "      <li>" >> ${index} 
      echo "      <a>${relative_url:1:${#relative_url}-6}</a> <a href=\"/${dirname}${relative_url}.json\">JSON</a>   <a href=\"/${dirname}${relative_url}/\">VIEWER</a>" >> ${index}

    fi
    echo "      </li>" >> ${index}
  fi
done
echo "    </ul>" >> ${index}
echo "  </div>" >> ${index}
echo "    </div>" >> ${index}
echo "      </div>" >> ${index}
echo "        </div>" >> ${index}
echo "      </div>" >> ${index}
echo "    </div>" >> ${index}
echo "        <footer>" >> ${index}
echo "          <address>" >> ${index}
echo "        <span class=\"hidden-xs\">Swiss Confederation</span>" >> ${index}
echo "        <nav class=\"pull-right\">" >> ${index}
echo "          <ul>" >> ${index}
echo "" >> ${index}
echo "             <li><a href=\"mailto:info@geo.admin.ch\">Contact</a></li>" >> ${index}
echo "           </ul>" >> ${index}
echo "        </nav>" >> ${index}
echo "      </address>" >> ${index}
echo "    </footer>" >> ${index}
echo "  </div>" >> ${index}
echo "</body>" >> ${index}
echo "</html>" >> ${index}

scp ${index}  ${scp_parameters}:${output_path}/index.html


