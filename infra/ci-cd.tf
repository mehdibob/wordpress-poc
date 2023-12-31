locals {
    deploy_cmd = <<EOT
                    gcloud components install kubectl
                    gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --zone ${google_container_cluster.cluster.location} --project ${var.GCP_PROJECT_ID}
                    kubectl scale --replicas=0 -n wordpress deployment/wordpress
                    kubectl scale --replicas=1 -n wordpress deployment/wordpress
                EOT
}



resource "google_cloudbuild_trigger" "wordpress" {
    depends_on = [time_sleep.wait_for_services]
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
                "wordpress-image.pkr.hcl"
            ]
            env        = []
            name       = "hashicorp/packer"
            secret_env = []
            wait_for   = []
        }
        step {
            entrypoint = "packer"
            args       = [
                "build",
                "-var",
                "GCP_PROJECT_ID=${var.GCP_PROJECT_ID}",
                "-var",
                "GCR_HOST=${var.GCP_GCR_HOST}",
                "wordpress-image.pkr.hcl"
            ]
            env        = []
            name       = "uapple/packer-docker-builder"
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

    github {
        owner = "mehdibob"
        name = "wordpress-poc"
        push {
            invert_regex = false
            branch = "main"
        }
    }

}
