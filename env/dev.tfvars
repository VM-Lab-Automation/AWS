project = "vm-lab-automation"
location = "us-east-1"
env = "dev"

shared_credentials_file = "../.aws/credentials"

database = {
  db_name = "vlab"
  username = "test_user"
  password_seed = "p1ssword"
  allocated_size = 10
  engine_type = "postgres"
  instance_class = "db.t3.micro"
}
