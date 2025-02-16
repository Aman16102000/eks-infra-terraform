# # Output the private key
# output "private_key" {
#   description = "Private key for the EKS key pair"
#   value       = tls_private_key.ssh_eks.private_key_pem
#   sensitive   = true
# }

# # Output the public key
# output "public_key" {
#   description = "Public key for the EKS key pair"
#   value       = tls_private_key.ssh_eks.public_key_openssh
# }
