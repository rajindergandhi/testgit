pipeline {
    agent any
    stages {
        stage('test1') {
            steps {
               sshagent(['test-dev']) {
               sh 'ssh -o StrictHostKeyChecking=no -l cloudbees ec2-user@ec2-52-40-7-228.us-west-2.compute.amazonaws.com uptime'
                sh 'echo "Hello World"'
                sh '''
                    echo "Multiline shell steps works too"
                    ls -lah
                '''
               }
            }
        }
    
        stage('test2') {
            steps {
                sh ''' echo "this is the second steps"
                '''
            }
        }
        stage('copy file') {
            steps {
                sshagent(['test-dev']) {
                    sh 'ssh -o StrictHostKeyChecking=no -l cloudbees ec2-user@ec2-52-40-7-228.us-west-2.compute.amazonaws.com hostname'
                   sh 'id'
                   sh 'cp -pr /tmp/test.sh /tmp/manish.sh'
                   sh 'cp -pr /tmp/manish.sh /tmp/rajinder/'
                    
                }
                
            }
        }
    }
}
