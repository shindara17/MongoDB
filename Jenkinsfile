pipeline {
    agent any

    environment {
        EKS_CLUSTER_NAME = 'myApp-eks-cluster'
        EKS_REGION = 'us-east-1'
        DOCKER_IMAGE = '<your-dockerhub-username>/my-web-app:latest'
        KUBECONFIG = credentials('kubeconfig')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(DOCKER_IMAGE)
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        docker.image(DOCKER_IMAGE).push()
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG
                        kubectl apply -f path/to/deployment.yaml
                        kubectl apply -f path/to/service.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
