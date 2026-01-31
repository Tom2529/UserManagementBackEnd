pipeline {
    agent any

    environment {
        TERRAFORM_DIR = 'environments/dev'  // folder containing your main.tf
    }

    stages {
        stage('Checkout') {
            steps {
                // Pull code from the Git repo
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir(env.TERRAFORM_DIR) {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(env.TERRAFORM_DIR) {
                    // Save plan to a file so apply uses the same plan
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir(env.TERRAFORM_DIR) {
                    // Apply the plan automatically
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}