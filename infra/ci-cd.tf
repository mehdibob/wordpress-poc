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
