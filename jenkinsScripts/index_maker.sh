#! /bin/bash

set -eu

resource_dir=""
resource_type=""
function usage {
  echo "Usage:"
  echo
  echo "-h  : show you this output here."
  echo -e "-d \t : the root directory to where your styles directories are stored."
  echo -e "-t \t : the type of resource you're looking for (style or tileset)"
  echo -e "-p \t : the protocol used to access the web server on which the files will be deployed (http or https)"
  echo -e "-s \t: the server address where files will be accessed"
  echo -e "example usage \t: ./jenkinsScripts/index_maker.sh -p \"/var/local/vectortiles/gl-styles\" -t \"style\""
}

while getopts :ht:d:s:p: opt "$@";do
  case ${opt} in
    h)
      usage
      exit
      ;;
    t)
      resource_type=${OPTARG}
      ;;
    d)
      resource_dir=${OPTARG}
      ;;
    s)
      servername=${OPTARG}
      ;;
    p)
      protocol=${OPTARG}
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

#TODO: trap to clean venv, venv and mako creation, mako templating later


index=${resource_dir}"/index.html"
title=""
case ${resource_type} in
  style)
  title="List of Gl Styles"
  title_fr=""
  title_de=""
  template_used="./jenkinsScripts/templates/style_viewer.html.in"
  ;;
  tileset)
  title="List of Map Box Tiles Datasets"
  title_fr=""
  title_de=""
  template_used="./jenkinsScripts/templates/mbtiles_viewer.html.in"
  ;;
  *)
  (>&2 echo "ERROR: UNSUPPORTED RESOURCE TYPE \"${resource_type}\"")
  exit 2
  ;;
esac
venv_path=".venv"
pip_path="${venv_path}/bin/pip"
mako_path="${venv_path}/bin/mako-render"
function cleanup {
  rm -rf "${venv_path}" || :
}

trap cleanup SIGHUP SIGINT SIGTERM EXIT

virtualenv ${venv_path}
${pip_path} install Mako==1.0.7
#HERE : TODO : write begin of template.

echo "<!DOCTYPE html>" > ${index}
echo "  <html>" >> ${index}
echo "    <body>" >> ${index}
echo "      <h1> ${title} </h1>" >> ${index}
echo "      <ul>" >> ${index}

dirname="${resource_dir##*/}"
for jsonfile in "${resource_dir}"/*/*/${resource_type}.json ; do
  if [ -f "${jsonfile}" ]; then
    style_name=$(jq '.name' ${jsonfile})
    let length_of_filename=${#resource_type}
    let length_of_filename+=6   
    relative_url="${jsonfile:${#resource_dir}}"
    let rel_url_length=${#relative_url}
    let rel_url_length-=${length_of_filename}
    relative_url=${relative_url:0:${rel_url_length}}
    ${mako_path} --var "servername"="${servername}" --var "protocol"="${protocol}" --var "${resource_type}_json"="${protocol}://${servername}/${dirname}${relative_url}/${resource_type}.json" --var "layername"="${style_name}" ${template_used} > ${resource_dir}${relative_url}/index.html
    echo "        <li>" >> ${index} 
    echo "          ${style_name} --> <a href=\"/${dirname}${relative_url}/${resource_type}.json\">\"JSON\"</a>   <a href=\"/${dirname}${relative_url}/index.html\">\"VIEWER\"</a>" >> ${index}
    echo "        </li>" >> ${index}
  fi
done
echo "      </ul>" >> ${index}

#HERE : TODO : write end of template
echo "    </body>" >> ${index}
echo "  </html>" >> ${index}
