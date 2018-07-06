#!/usr/bin/env groovy


final gitBranch = env.BRANCH_NAME
node(label: "jenkins-slave") {
  parameters {
    string(name: 'Destination', defaultValue: '', description: 'This should be empty, except to test the output in a separate folder')
    string(name: 'Efs', defaultValue: 'eu-west-1b.fs-da0ee213.efs.eu-west-1.amazonaws.com://dev/vectortiles', description: 'The volume in the efs where we write')
    string(name: 'Tiles', defaultValue: 'mbtiles', description: 'Where are the sources at localvolume/destination')
    string(name: 'LocalVolume', defaultValue: '/var/local/efs-dev/vectortiles', description: 'Where to mount the efs')
    string(name: 'GitPath', defaultValue: '.', description: 'The relative path to the git repository')
  }
}

try {
  stage("PositionCheck") {
    echo "Here, we will check that styles directories are at the root of the styles folder"
    echo "That the sprites are composed of one json and one png file with the same name in"
    echo "a style directory and."
    echo "That fonts are .pbf files that are in directories in the fonts directory"
  }
  
  stage("StylesSyntaxicCheck") {
    echo "Here, we will verify that we received jsons with coherent content for the styles"
  }

  stage("SpritesSyntaxicCheck") {
    echo "Here, we will verify that the sprites jsons are json and their content is as expected"
  }

  stage("NewFontsCheck") {
    echo "Here, we will verify if there are new fonts. It that's the case, we will set fonts "
    echo "to --fonts. If that's not the case, it will be an empty string. Fonts syncing is "
    echo "a time consuming process, so we might want to avoid having"
    def fontsparam="--fonts" 
  }


  if (gitBranch == 'master') {
    stage("Run") {
      //The script is meant to be called from the repository.
      sh "./jenkinsScripts/updateStyle.sh --efs=${params.Efs} --destination=${params.Destination} --mbtiles=${params.Tiles} --git=${params.GitPath} --mnt=${LocalVolume} $fontsparam"
    }
  }
} catch (e) {
  throw e
} finally {
  stage("Clean") {
    echo "The updateStyle script already delete its own created content."
    echo "This section is here for the time we decide to transfer the "
    echo "Cleaning to jenkins instead of the updater."
  }
}
