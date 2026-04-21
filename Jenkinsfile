pipeline {
    agent any

    environment {
        PROJECT_ID = "kong-gke-493913"
        KONNECT_SERVER_URL = "https://us.api.konghq.com"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/amanb15/Kong_GKE.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                terraform plan \
                -var="project_id=$PROJECT_ID" \
                -var="konnect_server_url=$KONNECT_SERVER_URL"
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                terraform apply -auto-approve \
                -var="project_id=$PROJECT_ID" \
                -var="konnect_server_url=$KONNECT_SERVER_URL"
                '''
            }
        }
    }
}
