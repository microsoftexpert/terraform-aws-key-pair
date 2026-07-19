###############################################################################
# EC2 Key Pair
#
# Registers a single, caller-supplied PUBLIC key with AWS so it can be named as
# the key_name when launching EC2 instances. The private key is generated and
# held by the caller and never touches this module, AWS, or Terraform state.
#
# Secure-by-default posture (a key pair has no data plane / encryption surface):
# - Public-key-only: the module accepts public_key and emits no secret. There
# is no aws_key_pair output that exposes private material.
# - Weak-algorithm rejection: variable validation rejects DSA (ssh-dss) keys;
# RSA (2048/4096) and ED25519 are the accepted, AWS-supported types.
#
# All three identity/material arguments (key_name, key_name_prefix, public_key)
# are FORCE-NEW — changing any of them replaces the key pair, which de-registers
# it from instances launched with it. There are no optional/repeating blocks and
# no timeouts block on this resource.
###############################################################################

resource "aws_key_pair" "this" {
 # Identity — set key_name OR key_name_prefix (mutually exclusive, enforced in
 # variables.tf). Both null lets Terraform generate a unique name.
 key_name = var.key_name
 key_name_prefix = var.key_name_prefix

 # Public key material (FORCE-NEW). AWS infers key_type from this material.
 public_key = var.public_key

 tags = var.tags
}
