pipeline {
    agent any

    environment {
        PROJECT_ID = "kong-gke-493913"
        KONNECT_SERVER_URL = "https://us.api.konghq.com"
        KONNECT_CONTROL_PLANE_ID = "473f901e-51fd-4e4a-babb-301219dc6b2e"
        CLUSTER_NAME = "kong-gke-gcp-project"
        ZONE = "us-central1-a"
    }

    stages {

        stage('Terraform Init') {
            steps {
                sh '''
                terraform init
                '''
            }
        }

        // 🔹 STEP 1: Create only GKE cluster
        stage('Create GKE Cluster') {
            steps {
                withCredentials([string(credentialsId: 'konnect-pat', variable: 'KONNECT_PAT')]) {
                    sh '''
                    terraform apply -auto-approve \
                    -target=google_container_cluster.cluster \
                    -target=google_container_node_pool.nodes \
                    -var="project_id=$PROJECT_ID" \
                    -var="konnect_server_url=$KONNECT_SERVER_URL" \
                    -var="konnect_control_plane_id=$KONNECT_CONTROL_PLANE_ID" \
                    -var="konnect_pat=$KONNECT_PAT"
                    '''
                }
            }
        }

        // 🔹 STEP 2: Wait for cluster readiness
        stage('Wait for Cluster') {
            steps {
                echo "Waiting for GKE cluster to stabilize..."
                sh 'sleep 120'
            }
        }

        // 🔹 STEP 3: Configure kubeconfig
        stage('Get Kubeconfig') {
            steps {
                sh '''
                gcloud container clusters get-credentials $CLUSTER_NAME \
                --zone=$ZONE \
                --project=$PROJECT_ID
                '''
            }
        }

        // 🔹 STEP 4: Verify cluster connectivity (very important debug step)
        stage('Verify Cluster Access') {
            steps {
                sh '''
                kubectl get nodes
                '''
            }
        }

        // 🔹 STEP 5: Deploy Kong + Gateway
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

        // 🔹 STEP 6: Final verification
        stage('Verify Deployment') {
            steps {
                sh '''
                kubectl get pods -n kong
                kubectl get svc -n kong
                kubectl get gateway -n kong
                '''
            }
        }
    }
}
