storage "file" {
  path    = "/mnt/rootn/openbao/data"
}

listener "tcp" {
  address       = "127.0.0.1:8200"
  tls_disable = 1
}

listener "tcp" {
  address       = "0.0.0.0:443"

  tls_cert_file = "/mnt/rootn/certs/cert.pem"
  tls_key_file  = "/mnt/rootn/certs/privkey.pem"
}

seal "static" {
  current_key_id = "20260207-1"
  current_key    = "file:///mnt/rootn/openbao/seal/20260207-1.key"
}

disable_mlock = true
ui = true

