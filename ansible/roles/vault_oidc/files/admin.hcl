# Allow all tools
path "sys/tools/*" {
  capabilities = [ "read" ]
}
path "sys/wrapping/*" {
  capabilities = [ "read" ]
}

# Read system health check
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth" {
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at 'salamandre/' and 'baku/' path

# List, create, update, and delete key/value secrets
path "salamandre/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "baku/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts" {
  capabilities = ["read"]
}

# Manage identies
path "identity/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Lookup leases
path "sys/leases/lookup" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "sys/leases/lookup/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Manage leases
path "sys/leases" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
path "sys/leases/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
