#! /bin/bash

set -eu

resource_dir=""
resource_type=""
function usage {
  echo "Usage:"
  echo
  echo "-h --help"
  echo -e "--path \t : the root path to where your styles directories are stored."
  echo -e "--type \t : the type of resource you're looking for (style or tileset)"
  echo -e "example usage \t: ./jenkinsScripts/index_maker.sh --path=\"styles\" --version=\"\""
  echo -e "another \t: ./jenkinsScript/index_maker.sh --path=\"/var/local/vectortiles/gl-styles\" --type=\"style\""
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
        --path)
            resource_dir=${VALUE}
            ;;
        --type)
            resource_type=${VALUE}
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
  fi
done
echo "      </ul>" >> ${index}

#HERE : TODO : write end of template
echo "    </body>" >> ${index}
echo "  </html>" >> ${index}
