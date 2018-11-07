#! /bin/bash

set -eu

resource_dir=""
resource_type=""
function usage {
  echo "Usage:"
  echo
  echo "-h  : show you this output here."
  echo -e "-p \t : the root path to where your styles directories are stored."
  echo -e "-t \t : the type of resource you're looking for (style or tileset)"
  echo -e "example usage \t: ./jenkinsScripts/index_maker.sh -p \"/var/local/vectortiles/gl-styles\" -t \"style\""
}

while getopts :ht:p: opt "$@";do
  case ${opt} in
    h)
      usage
      exit
      ;;
    t)
      resource_type=${OPTARG}
      ;;
    p)
      resource_dir=${OPTARG}
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

index=${resource_dir}"/index.html"
title=""
case ${resource_type} in
  style)
  title="SOME STYLES FOR VECTORTILES"
  ;;
  tileset)
  title="SAME AS ABOVE, BUT FOR SOURCES"
  ;;
  *)
  (>&2 echo "ERROR: UNSUPPORTED RESOURCE TYPE \"${resource_type}\"")
  exit 2
  ;;
esac

#HERE : TODO : write begin of template.

echo "<!DOCTYPE html>" > ${index}
echo "  <html>" >> ${index}
echo "    <body>" >> ${index}
echo "      <h1> ${title} </h1>" >> ${index}
echo "      <ul>" >> ${index}

dirname="${resource_dir##*/}"

for jsonfile in "${resource_dir}"/*/*/${resource_type}.json ; do
#TODO: VERIFY IT IS A DIRECTORY
  if [ -f "${jsonfile}" ]; then
    style_name=$(jq '.name' ${jsonfile})
    relative_url="/${dirname}${jsonfile:${#resource_dir}}"
    echo "        <li>" >> ${index} 
    echo "          ${style_name} --> <a href=\"${relative_url}\"></a>" >> ${index}
    echo "        </li>" >> ${index}
    case ${resource_type} in
      style)
      ;;
      tileset)
      ;;
      *)
      (>&2 echo "ERROR: UNSUPPORTED RESOURCE TYPE \"${resource_type}\"")
      exit 2
      ;;
    esac
  fi
done
echo "      </ul>" >> ${index}

#HERE : TODO : write end of template
echo "    </body>" >> ${index}
echo "  </html>" >> ${index}
