path "salamandre/*" {
  capabilities = [ "read" ]
}

path "baku/*" {
  capabilities = [ "read" ]
}

# Allow ESO to push and read TLSs
path "salamandre/data/tls/*" {
  capabilities = [ "create", "read", "update", "delete" ]
}
path "salamandre/metadata/tls/*" {
  capabilities = [ "create", "read", "update", "delete" ]
}
