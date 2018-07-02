#!/usr/bin/env groovy


node(label: "jenkins-slave") {
  final gitBranch = env.BRANCH_NAME
  final gitPath = "./config-tileservergl"
}

try {
  stage("Clone"){
    echo "Veryfing repository existence"
    def repoExists = sh 'if [ -d "./config-tileservergl/.git" ]; then echo 1; else echo 0; fi;'
    if (repoExists == 0){
      echo "Repository didn't exist. Cloning"
      sh 'git clone git@github.com:geoadmin/config-tileservergl.git'
      echo "Cloning finished"
    }
    else {
      echo "repository already exists. no need to clone it"
    }
  }
  stage("PositionCheck"){
    echo "Here, we will check that styles directories are at the root of the styles folder"
    echo "That the sprites are composed of one json and one png file with the same name in"
    echo "a style directory and."
    echo "That fonts are .pbf files that are in directories in the fonts directory"
  }
  
  stage("StylesSyntaxicCheck"){
    echo "Here, we will verify that we received jsons with coherent content for the styles"
  }

  stage("SpritesSyntaxicCheck"){
    echo "Here, we will verify that the sprites jsons are json and their content is as expected"
  }

  stage("NewFontsCheck"){
    echo "Here, we will verify if there are new fonts. It that's the case, we will set fonts "
    echo "to --fonts. If that's not the case, it will be an empty string. Fonts syncing is "
    echo "a time consuming process, so we might want to avoid having"
    def fontsparam="--fonts" 
}


  if (gitBranch == 'master') {
    stage("Run"){
//The script is meant to be called from the repository.
      sh 'cd .config-tileservergl'
      sh './updateStyle.sh '
    }

  }
} catch (e) {
  throw e
}
finally {
  stage("Clean") {
    echo "The updateStyle script already delete its own created content."
    echo "This section is here for the time we decide to transfer the "
    echo "Cleaning to jenkins instead of the updater."
  }


}
