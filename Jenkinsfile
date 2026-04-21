pipeline {
    agent any

    environment {
        PROJECT_ID = "kong-gke-493913"
        KONNECT_SERVER_URL = "https://us.api.konghq.com"
        KONNECT_CONTROL_PLANE_ID = "473f901e-51fd-4e4a-babb-301219dc6b2e"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/amanb15/Kong_GKE.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('KONG_GKE_STD') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([string(credentialsId: 'konnect-pat', variable: 'KONNECT_PAT')]) {
                    dir('KONG_GKE_STD') {
                        sh '''
                        terraform apply -auto-approve \
                        -var="project_id=$PROJECT_ID" \
                        -var="konnect_server_url=$KONNECT_SERVER_URL" \
                        -var="konnect_control_plane_id=$KONNECT_CONTROL_PLANE_ID" \
                        -var="konnect_pat=$KONNECT_PAT"
                        '''
                    }
                }
            }
        }
    }
}
