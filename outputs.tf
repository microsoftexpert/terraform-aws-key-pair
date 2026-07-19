###############################################################################
# Primary outputs (id + arn)
#
# For aws_key_pair the id IS the key pair name (the value you pass to an
# instance's key_name). key_pair_id (key-...) is the separate stable identifier
# used by some APIs and Config rules.
###############################################################################

output "id" {
 description = "The key pair name (equals key_name). This is the value wired into aws_instance.key_name."
 value = aws_key_pair.this.id
}

output "arn" {
 description = "The ARN of the key pair (cross-resource reference type: arn:aws:ec2:<region>:<account>:key-pair/<key-name>). Used by IAM policy / SCP conditions and Config rules."
 value = aws_key_pair.this.arn
}

output "key_pair_id" {
 description = "The stable key pair ID (key-...). Used by EC2 APIs (DescribeKeyPairs) and as a cross-resource reference distinct from the name."
 value = aws_key_pair.this.key_pair_id
}

###############################################################################
# Identity / material attributes
###############################################################################

output "key_name" {
 description = "The key pair name. Pass this as aws_instance.key_name / launch template key_name."
 value = aws_key_pair.this.key_name
}

output "key_type" {
 description = "The type of key pair AWS inferred from the public key material (\"rsa\" or \"ed25519\")."
 value = aws_key_pair.this.key_type
}

output "fingerprint" {
 description = "The MD5 public-key fingerprint as specified in section 4 of RFC 4716. Use to verify the registered key matches the caller's local key."
 value = aws_key_pair.this.fingerprint
}

###############################################################################
# Tags
###############################################################################

output "tags_all" {
 description = "All tags on the key pair, including those inherited from provider default_tags (resource tags win on key conflict)."
 value = aws_key_pair.this.tags_all
}
