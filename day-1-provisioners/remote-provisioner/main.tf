provider "aws" {
  region = "ap-south-1"
}

# Create EC2 instance to run remote commands
resource "aws_instance" "sql_runner" {
  ami                    = "ami-0f1dcc636b69a6438" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  key_name               = "mumbaikey"                # Replace with your key pair name
  associate_public_ip_address = true

  tags = {
    Name = "SQL Runner"
  }
}

# Create the RDS instance
resource "aws_db_instance" "mysql_rds" {
  identifier              = "my-mysql-db"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "venkatesh"
  db_name                 = "dev"
  allocated_storage       = 20
  skip_final_snapshot     = true
  publicly_accessible     = true
}

# Upload and execute SQL remotely
resource "null_resource" "remote_sql_exec" {
  depends_on = [aws_db_instance.mysql_rds, aws_instance.sql_runner]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/mumbaikey.pem")  # Update path if needed
    host        = aws_instance.sql_runner.public_ip
  }

  provisioner "file" {
    source      = "init.sql"
    destination = "/tmp/init.sql"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y mysql",
      "mysql -h ${aws_db_instance.mysql_rds.address} -u admin -pvenkatesh dev < /tmp/init.sql"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}
