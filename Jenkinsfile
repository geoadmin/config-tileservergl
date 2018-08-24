#!/usr/bin/env groovy
node(label: "jenkins-slave") {
  final gitBranch = env.BRANCH_NAME
  parameters {
    string(name: 'Destination', defaultValue: '', description: 'This should be empty, except to test the output in a separate folder'),
    string(name: 'Efs', defaultValue: 'eu-west-1b.fs-da0ee213.efs.eu-west-1.amazonaws.com://dev/vectortiles', description: 'The volume in the efs where we write'),
    string(name: 'Tiles', defaultValue: 'mbtiles', description: 'Where are the sources at localvolume/destination'),
    string(name: 'LocalVolume', defaultValue: '/var/local/efs-dev/vectortiles', description: 'Where to mount the efs'),
    string(name: 'GitPath', defaultValue: '.', description: 'The relative path to the git repository'
}

try {
  stage("PositionCheck"){
    sh './jenkinsScripts/positionChecker.sh'
  }
  
  stage("StylesSyntaxicCheck"){
    sh './jenkinsScripts/stylesSyntaxicChecker.sh'
  }

  stage("SpritesSyntaxicCheck"){
    sh './jenkinsScripts/spritesSyntaxicChecker.sh'
  }

  stage("NewFontsCheck"){
    def fontsparam= sh (
        script: './jenkinsScripts/newFontsChecker.sh'
        returnStdout: true
    ).trim()
}

  stage("SourcesJsonCheck"){
    sh '/jenkinsScripts/sourcesJsonChecker.sh'
}


  if (gitBranch == 'master') {
    stage("Run"){

//The script is meant to be called from the repository.
      sh "./jenkinsScripts/updateStyle.sh --efs=${params.Efs} --destination=${params.Destination} --mbtiles=${params.Tiles} --git=${params.GitPath} --mnt=${LocalVolume} $fontsparam"
    }

  }
} catch (e) {
  throw e
}
finally {
  stage("Clean") {
    sh './jenkinsScripts/cleanup.sh'
  }

}
}
