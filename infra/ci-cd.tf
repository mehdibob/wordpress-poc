locals {
    deploy_cmd = <<EOT
                    gcloud components install kubectl
                    gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --zone ${google_container_cluster.cluster.location} --project ${var.GCP_PROJECT_ID}
                    kubectl scale --replicas=0 -n wordpress --context=gke_${google_container_cluster.cluster.name}_${google_container_cluster.cluster.location}_${google_container_cluster.cluster.name} \
                    deployment/wordpress
                    kubectl scale --replicas=1 -n wordpress --context=gke_${google_container_cluster.cluster.name}_${google_container_cluster.cluster.location}_${google_container_cluster.cluster.name} \
                    deployment/wordpress
                EOT
}

resource "google_cloudbuild_trigger" "wordpress" {
    name           = "wordpress"
    description    = "CI/CD pipeline for wordpress application"
    disabled       = false

    build {
        images        = []
        substitutions = {}
        tags          = []

        step {
            args       = [
                "init",
            ]
            env        = []
            name       = "hashicorp/packer"
            secret_env = []
            wait_for   = []
        }
        step {
            args       = [
                "build",
                "-var \"GCP_PROJECT_ID=${var.GCP_PROJECT_ID}\"",
                "-var \"GCR_HOST=${var.GCP_GCR_HOST}\"",
                "wordpress-image.pkr.hcl"
            ]
            env        = []
            name       = "hashicorp/packer"
            secret_env = []
            wait_for   = []
        }
        step {
            args       = [
                "push",
                "${var.GCP_GCR_HOST}/${var.GCP_PROJECT_ID}/wordpress:latest",
            ]
            env        = []
            name       = "gcr.io/cloud-builders/docker"
            secret_env = []
            wait_for   = []
        }
        step {
            args       = [
                "-c",
                local.deploy_cmd,
            ]
            entrypoint = "bash"
            env        = []
            name       = "gcr.io/cloud-builders/gcloud"
            secret_env = []
            wait_for   = []
        }

    }

    # github {
    #     owner = "mehdibob"
    #     name = "wordpress-poc"
    #     push {
    #         invert_regex = false
    #         branch = "main"
    #     }
    # }

    source_to_build {
        uri       = "https://mehdibob/wordpress-poc"
        ref       = "refs/heads/main"
        repo_type = "GITHUB"
    }
}
