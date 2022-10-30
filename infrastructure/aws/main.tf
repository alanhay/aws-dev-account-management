resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-account-management-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-account-management-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

variable "names" {
  type    = set(string)
  default = ["alan_hay", "john_smith"]
}

# create some users
resource "aws_iam_user" "developer_accounts" {
  for_each = var.names
  name     = each.value
}

# create a developers group
resource "aws_iam_group" "developers_group" {
  name = "developers"
}

# add users to the developers group
resource "aws_iam_user_group_membership" "developers_group_membership" {
  for_each = var.names
  user     = aws_iam_user.developer_accounts[each.key].name
  groups   = [aws_iam_group.developers_group.name]
}

# define a policy for accessing the production role in the production account
data "aws_iam_policy_document" "allow_production_role_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::685471871711:role/production"]
  }
}

# create a policy based on this definition
resource "aws_iam_policy" "allow_production_role_policy" {
  name   = "allow_production_role_policy"
  policy = data.aws_iam_policy_document.allow_production_role_policy_document.json
}

# attach the production role policy to the developers group
resource "aws_iam_group_policy_attachment" "allow_developers_production_role" {
  group      = aws_iam_group.developers_group.name
  policy_arn = aws_iam_policy.allow_production_role_policy.arn
}

# ci/cd set-up
resource "aws_iam_user" "ci_cd_account" {
  name = "ci_cd"
  # permissions_boundary = "todo"
}

# define a policy for ci/cd
data "aws_iam_policy_document" "ci_cd_account_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*", "iam:*", "dynamodb:*", "organizations:*"]
    resources = ["*"]
  }
}

# create a policy based on this definition
resource "aws_iam_policy" "ci_cd_account_policy" {
  name   = "ci_cd_account_policy"
  policy = data.aws_iam_policy_document.ci_cd_account_policy_document.json
}

resource "aws_iam_policy_attachment" "ci_cd_account_policy_attachment" {
  name       = "ci_cd_account_policy_attachment"
  users      = [aws_iam_user.ci_cd_account.name]
  policy_arn = aws_iam_policy.ci_cd_account_policy.arn
}



resource "aws_s3_bucket" "sample_bucket" {
  bucket = "ah-dev-sample-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "sample_bucket_versioning" {
  bucket = aws_s3_bucket.sample_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sample_bucket_encryption" {
  bucket = aws_s3_bucket.sample_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


####################################################

data "aws_organizations_organization" "root_organization" {

}

resource "aws_organizations_organizational_unit" "developers" {
  name      = "developers"
  parent_id = data.aws_organizations_organization.root_organization.roots[0].id
}
