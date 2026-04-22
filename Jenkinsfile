pipeline {
    agent any

    environment {
        PROJECT_ID = "kong-gke-493913"
        KONNECT_SERVER_URL = "https://us.api.konghq.com"
        KONNECT_CONTROL_PLANE_ID = "473f901e-51fd-4e4a-babb-301219dc6b2e"
    }

    stages {

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        // 🔹 STEP 1: Create only cluster
        stage('Create GKE Cluster') {
            steps {
                sh '''
                terraform apply -auto-approve \
                -target=google_container_cluster.cluster \
                -target=google_container_node_pool.nodes \
                -var="project_id=$PROJECT_ID"
                '''
            }
        }

        // 🔹 STEP 2: Wait for cluster to be ready
        stage('Wait for Cluster') {
            steps {
                echo "Waiting for GKE cluster to be ready..."
                sh 'sleep 120'
            }
        }

        // 🔹 STEP 3: Get credentials (VERY IMPORTANT)
        stage('Get Kubeconfig') {
            steps {
                sh '''
                gcloud container clusters get-credentials kong-gke-gcp-project \
                --zone=us-central1-a \
                --project=$PROJECT_ID
                '''
            }
        }

        // 🔹 STEP 4: Apply full Terraform (Kong + Gateway)
        stage('Deploy Kong + Gateway') {
            steps {
                withCredentials([string(credentialsId: 'konnect-pat', variable: 'KONNECT_PAT')]) {
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
