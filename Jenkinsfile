pipeline {
    agent any

    environment {
        PROJECT_ID = "kong-gke-493913"
        KONNECT_SERVER_URL = "https://us.api.konghq.com"
        KONNECT_CONTROL_PLANE_ID = "47da2826-53e2-44c3-a036-9bedb2bd27fd"
        CLUSTER_NAME = "kong-gke-gcp-project"
        ZONE = "us-central1-a"
    }

    stages {

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        // 🔹 STEP 1: Create GKE cluster
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

        // 🔹 STEP 2: Get kubeconfig
        stage('Get Kubeconfig') {
            steps {
                sh '''
                gcloud container clusters get-credentials $CLUSTER_NAME \
                --zone=$ZONE \
                --project=$PROJECT_ID
                '''
            }
        }

        // 🔹 STEP 3: Wait until cluster is actually ready (SMART WAIT)
        stage('Wait for Cluster Ready') {
            steps {
                sh '''
                kubectl wait --for=condition=Ready nodes --all --timeout=300s
                '''
            }
        }

        // 🔹 STEP 4: Install Gateway API (PERMANENT FIX)
        stage('Install Gateway API') {
            steps {
                sh '''
                kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --validate=false
                '''
            }
        }

        // 🔹 STEP 5: Verify cluster
        stage('Verify Cluster Access') {
            steps {
                sh 'kubectl get nodes'
            }
        }

        // 🔹 STEP 6: Deploy Kong + Gateway
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

        // 🔹 STEP 7: Final verification
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
