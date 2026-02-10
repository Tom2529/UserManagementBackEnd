terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-west-1"  # Change this if needed
}

resource "aws_instance" "usermgmtdb" {
  ami = "ami-0290e60ec230db1e4"  # Make sure this AMI has MySQL or is a base Linux AMI
  instance_type = "t3.medium"
  
  # User data to install MySQL, modify config, and run SQL commands
  user_data = <<-EOF
  #!/bin/bash

  # Update the system and install MySQL server
  sudo apt update -y
  sudo apt install mysql-server -y

  # Start MySQL service
  sudo systemctl start mysql
  sudo systemctl enable mysql

  # Modify MySQL config to allow connections from any host (0.0.0.0)
  sudo sed -i 's/^bind-address\s*=.*$/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
  sudo sed -i 's/^mysqlx-bind-address\s*=.*$/mysqlx-bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

  # Restart MySQL to apply config changes
  sudo systemctl restart mysql

  # Create MySQL admin user accessible from anywhere and grant privileges
  sudo mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin';"
  sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;"
  sudo mysql -e "FLUSH PRIVILEGES;"

  # Optionally, verify the new user
  sudo mysql -e "SELECT user, host FROM mysql.user WHERE user = 'admin';"

  # Exit MySQL
  sudo mysql -e "EXIT;"

  EOF

  tags = {
    Name = "usermgmtdb"
  }
}

# Output the public IP address of the EC2 instance
output "usermgmtdb_public_ip" {
  value = aws_instance.usermgmtdb.public_ip
}
