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

For now, the efs is in `eu-west-1b.fs-da0ee213.efs.eu-west-1.amazonaws.com://[STAGING]/vectortile`
Configuration Generation for Tile Server GL

using the makefile in the docker directory

make build
make push
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
For rasters, `local://` will be replaced with the hostname.

for sprites and glyphs, anything that isn't a direct URL (`http(s):// ...`) will be transformed. 

you should use 
```JSON
"sprite" : "[id]/[version]/sprite",
"glyphs" : "local://fonts/{fontstack}/{range}.pbf",
```
for glyphs, this template corresponds to what it would become whatever you put in that spot. To keep consistency between what is deployed and what is in the files, we recommend using the template. 

for sprites, anything put in there will create a route (`local://gl-style/[style_complete_id]/sprite`) that will lead to `[path_to_sprites_folder]/[sprite_field]`
for example, if you tried to put "`local://stylename/v001/sprite`" it would link to "/var/local/efs-xxx/vectortiles/sprites/local://stylename/v001/sprite", which isn't helpful. 
By giving `stylename/v001/sprite` it will lead to /var/local/efs-xxx/vectortiles/sprites/stylename/v001/sprite, which is where your sprites are supposed to be stored.


#Tile Server GL: Full documentation on deploy, locations and use

## 1. Git Repositories
There are five (plus one) important repositories in the vib2d project, which tileserver is a part of. They have all some level of use and if you need to alter tileserver comportment, those are important to know. 

### 1. config-tileservergl (https://github.com/geoadmin/config-tileservergl)
  The current repository. It is meant to 
  store the styles, the fonts, the sprites and the external jsons
  store the dockerfiles for tileserver sidekicks, namely the configuration generator for tileserver and the configuration for nginx. 
  build and push those configurations
  Deploy styles, fonts, sprites and jsons to the efs.
  
  Later in this document, this will be called the config repository
  
### 2. tileserver-gl (https://github.com/geoadmin/tileserver-gl)
  Tileserver GL source code. It would be better to use a vanilla version, but as we need functionalities that are not present within vanilla version, we use our own version instead.
  
  Later in this document, this will be called the code repository
  
### 3. tool tileserver builder (https://github.com/geoadmin/tool-tileserver-builder)
  This repository exists to build and push the docker images of tileserver GL. As such, it has the code repository as a submodule.
  
    Later in this document, this will be called the builder repository
### 4. tool project deployer (https://github.com/geoadmin/tool-project-deployer)
  This repository will hopefully not be only used by tileserver GL. The goal is to provide easy to use deploy and local run procedures for all projects using docker.
    Later in this document, this will be called the deploy repository
    
### 5. lib makefiles (https://github.com/geoadmin/lib-makefiles)
  This repository contains makefiles libraries meant to be called by multiple projects. This is only used as a submodule in the builder, the deploy and the config repositories, and is called by those repositories' makefiles.

### 6. Tippecanoe (https://github.com/geoadmin/service-tileservergl)
This repo contains one script to call tippecanoe and its readme tells you how to install tippecanoe and use this script (https://github.com/geoadmin/service-tileservergl#all-in-one-script) . It should be migrated to another repository, but it has its own entry here for now.

## 2. Files locations and naming conventions
  Tileserver uses diverses files to function. It uses SQlite3 databases as sources (.mbtiles files), JSON style files, fonts, wmts description jsons, sprites (both PNG and their JSON descriptions). This section will details where those files should end, how they should be called and how to put them here. 
  
### 1. Sources 
  Sources are .mbtiles files, which are SQLite3 databases containing one or multiple layers for styling. They are not stored in any git repository and are directly deployed to the efs. Sources and code are independant. If you try to deploy a dev version, the configuration generation will pick sources from the development efs. That way, integrators can use a stable version of tileserver to work on int, on which they can deploy as many sources as needed, while developers can use a few to test things with their code modifications. 
  
  In the efs, sources are stored under `vectortiles/mbtiles/{name}/{version}/tiles.mbtiles` with `{name}` being the technical name of the source and `{version}` a string giving the version of the source (`v001` - `v999`). A source's version should only change when the attributes between the two versions are different. to upload a source to the efs, use the following command (assuming your source, locally, is in the same structure : `{name}/{version}/tiles.mbtiles`  
  ```BASH scp -r {PATH_TO_SOURCE}/{name}/ geodata@10.220.5.211:/var/local/efs-{staging}/vectortiles/mbtiles/{name}``` 

for sources to be taken into account, the server needs to be redeployed from the deploy repository.

### 2. Styles
Styles are .json files that describes how differents sources should be rendered by the server. They should be stored in this very git repository, which would then upload them to the efs thanks to a script, stored under jenkinsScripts/updateStyles.sh.
Alternatively, you can deploy them directly to the efs the same way you did the sources. 


The naming convention is similar to the one of sources, with the styles stored, in the efs, under `vectortiles/styles/{name}/{version}/style.json`. In this repository, they should be stored in `styles/{name}/style.json`, as the version will be automatically added to the style upon deployment.

If you plan to deploy your style manually, use the following scp command : 
```BASH scp -r {PATH_TO_STYLE}/{name}/{version}/ geodata@10.220.5.211:/var/local/efs-{staging}/vectortiles/styles/{name}/{version}```

If you plan on using the deploy script, you will be calling it from this repository root like so : 

```BASH ./jenkinsScripts/updateStyle.sh --destination="" --efs={EFS_SERVER} --mnt={EFS_MOUNTING_POINT} --env={STAGING} ```

an optional flag, `--fonts` allow to deploy fonts as well. As deploying fonts takes a ton of time, unless you added a new fonts, I recommend not using it.

### 3. Fonts

Fonts are files that are stored in this repository and in the efs under `fonts` and `vectortiles/fonts` respectively. The fonts directory in the efs should be a 1-1 replica of the fonts in this repository.

### 4. Sprites

Sprites are PNG images that are part of the styles, and JSON files that describe which part of the image correspond to which element on the maps. those files are stored in this repository under `styles/{name}/sprites/sprite[@(2|3?)].[json|png]$`, and deployed to the efs under `vectortiles/sprites/{name}/{version}/sprite[@(2|3?)].[json|png]$`

They should be deployed with the script that deploys styles, or can be uploaded manually thanks to a scp command like this one : 
```BASH scp -r {PATH_TO_SPRITES}/{name}/{version}/ geodata@10.220.5.211:/var/local/efs-{staging}/vectortiles/sprites/{name}/{version}```
The `{name}` should be the technical name of the style using these sprites, and the `{version}` should be the same as the deployed version of the style. 

### 5. wmts jsons

Wmts jsons are JSON files describing an external wmts resource, describing some properties from the wmts as well as an URL to load the corresponding tiles. There is no special conventions on how those jsons should be named, but it is considered good practice to have a self-explanative name. 

They are stored in this repository under `json_sources/{name}.json`, and in the efs under `/vectortiles/json/{name}.json`

As other files stored within this repository, they are part of the standard script procedure for uploads, and can be uploaded manually with a scp command : 
```BASH scp {PATH_TO_JSON}/example.json geodata@10.220.5.211:/var/local/efs-{staging}/vectortiles/jsons/example.json```


## 3. Makefiles commands and their use

Multiple makefiles command are present across all repositories to help build and deploy tileserver in a simple fashion. 

### 1. Building tileserver

In the builder repository, two Makefiles command exists : 

`Make build` and `Make push`. If the repository status is not clean (files have changed and are either not added, or not commited), the image tag will be "unstable". If the repository status is clean, the tag will be the shortened commit hash. 

for `Make build` to work, the ORGNAME environment variable should be set to swisstopo. If it isn't set, the following should appear on your screen : 
```
Environment variable ORGNAME not set.
Makefile:14: recipe for target 'build' failed
```
If the variable is set, it should start to build the image for the container.

when using `Make push`, you should have an output like this one :

```
swisstopo/tileserver-gl:unstable
The push refers to a repository [docker.io/swisstopo/tileserver-gl]
8770ebc495d8: Pushed 
55e895a91d80: Pushed 
ffc451f2e09c: Layer already exists 
055ad34ccd95: Layer already exists 
cdd5212b4ec2: Layer already exists 
0d2a880563e6: Layer already exists 
9f91c21c42a2: Layer already exists 
d8293569bfa4: Layer already exists 
c4d021050ecd: Layer already exists 
9978d084fd77: Layer already exists 
1191b3f5862a: Layer already exists 
08a01612ffca: Layer already exists 
8bb25f9cdc41: Layer already exists 
f715ed19c28b: Layer already exists 
```

As you can see on the first line, you can find the image full name. The tag in this example is, "unstable".

### 2. Building the configuration

The configurations for tileserver and nginx are build in this repository, and the makefiles lies in the docker directory. From there, call `Make build` and `Make push` to build and push the configurations. 

Nginx is a static configuration while tileserver is a dynamic configuration that is generated on the fly on a new run or deploy, based on the directories in the corresponding efs. This can generate two different configurations depending on which image tag you use. 
`8fb00a6` will create an id with underscores replacing the slashes in the path (for example, a source in `mbtiles/exampleSource/version/tiles.mbtiles` will become `exampleSource_version`)
`387011b` will create an id which translate directly the paths to an id (with the same example as before, the id would be `exampleSource/version`) 
This configuration generation expects the file system's architecture to be as described before in section 2. 

### 3. Running Tileserver locally

From the deploy repository, the generic command `Make run-{PROJECT}-{STAGING}` can run any project with a directory in the repository. As tileservergl is one of the directories of this project, you can call `Make run-tileservergl-{STAGING}`, `{STAGING}` being either dev, int or prod. 

Inside the tileservergl, you'll find the following important files : 
```
dev.arg
dev.env
docker-compose.yml.in
int.arg
int.env
prod.arg
prod.env
rancher-compose.yml.in
```
the `*.arg` files contan arguments for the mako rendering of the docker compose and rancher compose. If you open, for example, dev.arg : 
```dev.arg
--var staging=dev
--var nginx_config_tag=5ce7236
--var tileserver_tag=7b81177
--var nginx_tag=1.14
--var ci=false
--var config_tag=387011b
```
It mainly gives you the tags for the images used in the dev version of tileserver. If you want to test an unstable version of tileservergl, you can change `tileserver_tag` value to `unstable`, and you're ready to test your changes with the rest of the containers remaining unchanged. 

the `*.env` files contain environment variables used by the docker compose file. Unless a new implementation of one of the different containers requires a new environment variable, or we change some conventions, you shouldn't need to change this file. Its content is quite self explanatory. 

```dev.env
STYLES=styles
TILES=mbtiles
FONTS=fonts
SPRITES=sprites
SERVERPATH=mbtiles
SERVER_DATA_PATH=mbtiles
SERVER_STYLES_PATH=gl-styles
```
finally, templates for the docker compose and rancher compose file (`*.in` files). If you need to change them, that means the containers architecture has changed, and that some parts of this documentation might be out of date.

### 4. Deploying Tileserver to Rancher

The same as running locally, but you need to use `rancherdeploy-tileservergl-{STAGING}` instead of `run`. If you do not have the accesses to rancher within your workstation, you will be denied your command and you won't be able to deploy. If you're denied and you would be supposed to be able to deploy tileserver on the desired environment, make the necessary procedures to get these accesses. 
If you were not supposed to have these accesses, then don't use this command as it will not do anything.

## 4. How to work in the differents parts of tileserver ?


## 5. Proper Workflow

## 6. How to create sources

## 7. How to create styles
