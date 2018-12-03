# config-tileserver-gl

## Adding new styles to the configuration

1) Create a branch and switch to it. A good branch naming convention would be  ${Collaborator_id}\_${subject}\_${stylename}
  For example : ltkum_new_style_hikingtrails
2) Store your style (or your fonts, or your sprites) in the corresponding directory. 
  For example : styles/hikingtrails/style.json
3) Usually, sprites are stored in the same folder as the styles they depends on. 
4) Push to github, ask for a PR, see if jenkins tells you it is okay. Once it's done, you merge and voila, a new style is updated.

Note: Work was done to allow maputnik to save directly styles to this repository. Once I have more informations, I'll update this repository help again.

## Updating a new style to the configuration

### Deploy the styles to the efs (valid until we manage to make a correct Jenkinsfile)

From the command line within the repository root, call the following script 

```bash
./jenkinsScripts/updateStyle.sh --destination="" --efs="${SERVER}://${STAGING}/vectortiles" --mnt="/var/local/efs-${STAGING}/vectortiles"
```

${SERVER} is the efs server. ${STAGING} is either dev, int or prod, depending on where you're deploying those. 
If you intend to deploy fonts, you can add the --fonts option, but be warned that it will rsync all fonts with the efs and that it is taking a lot of time.

### That's it

For now, the efs is in "eu-west-1b.fs-da0ee213.efs.eu-west-1.amazonaws.com://dev/vectortiles"
Configuration Generation for Tile Server GL

using the makefile in the docker directory

make build-development|integration|production to build an image
make push-development|integration|production to push them to docker hub
```
docker run --rm -v [PATH_TO_TILES]:[PATH_TO_TILES] [IMAGE]:[TAG] to run it locally. In the end, it should be called by the docker compose.
```

## Addding a new dataset to the efs

Sometimes, you will need to add a new map box tiles data source to the efs. You will find here the documentation allowing you to proceed.

### obtain your geojson

You're supposed to have a geojson as your basic data. This data should be in web mercator projection(EPSG:3857) For our example, we will call this data example.geojson



### Templating in styles

Tileserver gl makes use of templating to link resources on the system to its routes. The following templates are supported : 

IN SOURCES : 
``` JSON
"[source_identifier_for_the_style_file]" : {
"url" : "mbtiles://{source_id/source_version}",
"type" : "vector"
}, ...
```
This allows for an easy way to link sources and styles. It will look for the source in the directory specified for mbtiles in the configuration. It also replace the url by a route according to tileserver configuration.

``` JSON
"[source_identifier]" : {
"url": "local://json/[json_file_name]",
"type" : "raster"
}, ...
```
For rasters, local:// will be replaced with the hostname.

for sprites and glyphs, anything that isn't a direct URL ("http(s):// ...") will be transformed. 

you should use 
```JSON
"sprite" : "[id]/[version]/sprite",
"glyphs" : "local://fonts/{fontstack}/{range}.pbf",
```
for glyphs, this template corresponds to what it would become whatever you put in that spot. To keep consistency between what is deployed and what is in the files, we recommend using the template. 

for sprites, anything put in there will create a route (local://gl-style/[style_complete_id]/sprite) that will lead to [path_to_sprites_folder]/[sprite_field]
for example, if you tried to put "local://stylename/v001/sprite" it would link to "/var/local/efs-xxx/vectortiles/sprites/local://stylename/v001/sprite", which isn't helpful. 
By giving stylename/v001/sprite it will lead to /var/local/efs-xxx/vectortiles/sprites/stylename/v001/sprite, which is where your sprites are supposed to be stored.



