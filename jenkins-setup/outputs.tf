output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins RHEL Server"
  value       = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}

output "jenkins_access_url" {
  description = "Web URL to access Jenkins"
  value       = "http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080"
}

output "jenkins_agent_public_ip" {
  description = "Public IP address of the Dedicated Jenkins Agent VM"
  value       = google_compute_instance.jenkins_agent.network_interface[0].access_config[0].nat_ip
}
