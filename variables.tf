###############################################################################
# Name (key pair identity)
#
# An EC2 key pair's identity is its name. The provider lets you set an explicit
# key_name, a key_name_prefix (server-generated unique name), or neither (in
# which case Terraform generates a name). All three are FORCE-NEW. key_name leads
# the file as the primary identity, per house style.
###############################################################################

variable "key_name" {
 description = <<EOT
The explicit name for the EC2 key pair. FORCE-NEW — changing it destroys and
recreates the key pair (and de-registers it from any instances launched with it).
Conflicts with key_name_prefix. Null (default) means the name is derived from
key_name_prefix, or — if that is also null — Terraform generates a unique name.
Max 255 ASCII characters.
EOT
 type = string
 default = null

 validation {
 condition = var.key_name == null || (length(var.key_name) >= 1 && length(var.key_name) <= 255)
 error_message = "key_name must be between 1 and 255 characters."
 }

 # key_name and key_name_prefix are mutually exclusive (the provider rejects
 # both being set).
 validation {
 condition = !(var.key_name != null && var.key_name_prefix != null)
 error_message = "Set either key_name or key_name_prefix, not both (they conflict)."
 }
}

variable "key_name_prefix" {
 description = <<EOT
Creates a unique key pair name beginning with this prefix. FORCE-NEW — changing
it recreates the key pair. Conflicts with key_name. Null (default) means no
prefix-based naming is used. Use this (instead of key_name) when many key pairs
must coexist without name collisions. The prefix portion is limited to 255
characters minus the random suffix the provider appends.
EOT
 type = string
 default = null

 validation {
 condition = var.key_name_prefix == null || (length(var.key_name_prefix) >= 1 && length(var.key_name_prefix) <= 255)
 error_message = "key_name_prefix must be between 1 and 255 characters."
 }
}

###############################################################################
# Public key material (required, FORCE-NEW)
#
# This module imports a CALLER-SUPPLIED public key. The matching PRIVATE key is
# generated and held by the caller and is never passed to this module, never
# sent to AWS, and never written to Terraform state — that separation is the
# core secure-by-default posture of a key-pair module (an EC2 key pair has no
# encryption-at-rest surface of its own).
###############################################################################

variable "public_key" {
 description = <<EOT
The public key material to register with AWS. Required. FORCE-NEW — changing it
destroys and recreates the key pair. AWS supports OpenSSH public-key format (the
~/.ssh/authorized_keys form, e.g. "ssh-ed25519 AAAA..."), base64-encoded DER, and
the RFC 4716 SSH public-key file format. EC2 accepts RSA (2048/4096-bit) and
ED25519 keys (ED25519 is not usable by Windows instances). Supply ONLY the public
key — never the private key (the private key stays with the caller and must not
enter Terraform state).
EOT
 type = string

 validation {
 condition = length(trimspace(var.public_key)) > 0
 error_message = "public_key must not be empty — supply the public key material to import."
 }

 # Secure-by-default: reject the legacy, weak DSA key type. AWS does not support
 # DSA for EC2 key pairs and DSA is below the cryptographic baseline. This
 # only fires on OpenSSH-format keys (DER / RFC4716 forms do not start with a
 # type token), so valid imports are never blocked.
 validation {
 condition = !startswith(trimspace(var.public_key), "ssh-dss")
 error_message = "DSA (ssh-dss) keys are not permitted — use an RSA (2048/4096-bit) or ED25519 key. AWS does not support DSA for EC2 key pairs."
 }
}

###############################################################################
# Universal tail
#
# aws_key_pair exposes no timeouts block, so this module ends at tags.
###############################################################################

variable "tags" {
 description = <<EOT
A map of tags to assign to the EC2 key pair. These merge with provider-level
default_tags; resource tags win on key conflict. The computed tags_all output
reflects the merged set.
EOT
 type = map(string)
 default = {}
}
