# 1. Create Firewall Rule for Jenkins Port 8080
resource "google_compute_firewall" "allow_jenkins" {
  name    = "allow-jenkins-8080"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags   = ["jenkins-server"]
  source_ranges = ["0.0.0.0/0"]
}

# 2. Create Jenkins RHEL VM (N-2 Version for Upgrade Practice)
resource "google_compute_instance" "jenkins_vm" {
  name         = "jenkins-rhel-server"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["jenkins-server"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-8" # N-1/N-2 OS Version
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = <<EOF
#!/bin/bash
dnf update -y
dnf install -y java-17-openjdk git curl wget dnf-plugins-core

# Install Docker
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker

# Install pinned Jenkins N-2 Version (v2.541.1-1)
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins-2.541.1-1
systemctl enable --now jenkins
usermod -aG docker jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Open RHEL OS Firewall for Port 8080
firewall-cmd --permanent --add-port=8080/tcp || true
firewall-cmd --reload || true
EOF
}
