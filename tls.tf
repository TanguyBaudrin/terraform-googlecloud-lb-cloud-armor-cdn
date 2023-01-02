resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  validity_period_hours = 48

  early_renewal_hours = 3

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["test.com"]

  subject {
    common_name  = "test.com"
    organization = "Test"
  }
}

resource "google_compute_ssl_certificate" "this" {
  name        = "ssl-cert"
  private_key = tls_private_key.this.private_key_pem
  certificate = tls_self_signed_cert.this.cert_pem
}
