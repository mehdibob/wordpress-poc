variable "GCP_PROJECT_ID" {}
variable "GCR_HOST" {}
source "docker" "ubuntu" {
  changes = [   "ENV DEBIAN_FRONTEND=noninteractive",
                "ENV DB_HOST DB_NAME DB_USER DB_PASSWORD",
                "ENV APACHE_RUN_USER www-data",
                "ENV APACHE_RUN_GROUP www-data",
                "ENV APACHE_LOG_DIR /var/log/apache2",
                "ENV APACHE_PID_FILE /var/run/apache2.pid",
                "ENV APACHE_RUN_DIR /var/run/apache2",
                "ENV APACHE_LOCK_DIR /var/lock/apache2",
                "USER www-data",
                "EXPOSE 80",
                "ENTRYPOINT /entrypoint.sh"
            ]
  commit  = true
  image   = "ubuntu:jammy"
}

build {
  sources = ["source.docker.ubuntu"]
  provisioner "shell" {
    inline = ["export DEBIAN_FRONTEND=noninteractive;apt-get -y update;apt-get install -y tzdata;ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime;dpkg-reconfigure --frontend noninteractive tzdata;apt-get install -y software-properties-common;apt-add-repository ppa:ansible/ansible;apt-get -y update;apt-get install -y ansible"]
  }
  provisioner "ansible-local" {
    playbook_file = "ansible/provisioner.yaml"
  }
  post-processor "docker-tag" {
    repository = "${var.GCR_HOST}/${var.GCP_PROJECT_ID}/wordpress"
    tags = ["latest"]
  }
}
