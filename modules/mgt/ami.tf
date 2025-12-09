data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["877059142592"]
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["gel-baseline-amazon-linux_2023-*"]
  }
}
