function create_list(resource) {
  fetch("/"+resource+"/resources.json").then(
    res => res.json()
).then(
    data => {

      var element = document.getElementById("listing");
      var ulNode = document.createElement("UL");
    
      var viewerName = resource == "mbtiles" ?  "inspect" : "viewer";
      var jsonName = resource == "mbtiles" ? "tileJSON" : "style json" ;
      var jsonSuffix = resource == "mbtiles" ? ".json" : "/style.json";
      var viewerSuffix = resource == "mbtiles" ? "#6/46/7" : "";
      var template = data["template_url"];
      if (typeof(data[resource]) == 'object'){
        for (var layer in data[resource]) {
          var liNode = document.createElement("LI");
          var textNode = document.createTextNode(layer);
          liNode.appendChild(textNode);
          ulNode.appendChild(liNode);
          var internalUlNode=document.createElement("UL");
          for (var versionIdx in data[resource][layer]['versions']) {
            var version = data[resource][layer]['versions'][versionIdx];
            var internalLiNode = document.createElement("LI");
            var versionTextNode = document.createTextNode(version + '    ');
            var internalLinkJson = document.createElement("A");
            var jsonText= document.createTextNode(jsonName + '    ');
            internalLinkJson.appendChild(jsonText);
            internalLinkJson.title = jsonName;
            internalLinkJson.href = template.replace("{resource}",resource).replace("{name}",layer).replace("{version}",version).replace("{resource_type}",jsonSuffix) ;

            var internalLinkViewer = document.createElement("A");
            var viewerText = document.createTextNode(viewerName);
            internalLinkViewer.appendChild(viewerText);
            internalLinkViewer.title = viewerName;
            internalLinkViewer.href = template.replace("{resource}",resource).replace("{name}",layer).replace("{version}",version).replace("{resource_type}","/viewer.html") + viewerSuffix ;

            internalLiNode.appendChild(versionTextNode);
            internalLiNode.appendChild(internalLinkJson);
            internalLiNode.appendChild(internalLinkViewer);
          }
        internalUlNode.appendChild(internalLiNode);
        ulNode.appendChild(internalUlNode);
        }  
      }
    element.appendChild(ulNode); 
    }

  )
}
