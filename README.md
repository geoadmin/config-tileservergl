# config-tileserver-gl

### Adding new styles to the configuration

1) Create a branch and switch to it. A good branch naming convention would be  ${Collaborator_id}\_${subject}\_${stylename}
  For example : ltkum_new_style_hikingtrails
2) Store your style (or your fonts, or your sprites) in the corresponding directory. 
  For example : styles/hikingtrails/style.json
3) Usually, sprites are stored in the same folder as the styles they depends on. 
4) Push to github, ask for a PR, see if jenkins tells you it is okay. Once it's done, you merge and voila, a new style is updated.

Note: Work was done to allow maputnik to save directly styles to this repository. Once I have more informations, I'll update this repository help again.

### Updating a new style to the configuration

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

docker run --rm -v /var/local/efs-dev/vectortiles/:/var/local/efs-dev/vectortiles/ {swisstopo/config-tileserver}:{tag} to build it locally. your docker compose should make it for you,

