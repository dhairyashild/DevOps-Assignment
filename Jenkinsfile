pipeline{
  agent any

  tools{
        nodejs 'nodejs'  // Configure in Jenkins Global Tool Configuration
    }

  environment {
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        AWS_REGION = 'ap-south-1'
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    }
  stages{
    stage(checkout_code){
      steps{
        checkout scm
            echo "Building branch: ${BRANCH_NAME}"
            }
    }
    }
}
