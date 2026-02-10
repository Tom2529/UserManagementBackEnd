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

resource "aws_security_group" "usermgmtdb_sg" {
  name        = "usermgmtdb_sg"
  description = "Security group for MySQL access and other required ports"
  
  # HTTP Rule (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP access from any IP
  }

  # MySQL/Aurora Rule (Port 3306)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow MySQL access from any IP
  }

  # Custom TCP Rule (Port 4200)
  ingress {
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Custom TCP on port 4200 from any IP
  }

  # SSH Rule (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from any IP (be cautious)
  }

  # Custom TCP Rule (Port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Custom TCP on port 8080 from any IP
  }

  # Allow all outbound traffic (default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "usermgmtdb_sg"
  }
}


resource "aws_instance" "usermgmtbe" {
  ami = "ami-0290e60ec230db1e4"  
  instance_type = "t3.medium"
  security_groups = [aws_security_group.usermgmtdb_sg.name]
  
  #Make sure indentation is done property as shown below
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install openjdk-21-jdk -y
  sudo apt install maven -y
  sudo apt install git -y  
  EOF

  tags = {
    Name = "usermgmtbe"
  }
}

# Output the public IP address of the EC2 instance
output "usermgmtbe_public_ip" {
  value = aws_instance.usermgmtbe.public_ip
}

resource "aws_instance" "usermgmtfe" {
  ami           = "ami-0290e60ec230db1e4"  
  instance_type = "t3.medium"
  
  security_groups = [aws_security_group.usermgmtdb_sg.name]
  
  # User data to install necessary software including Node.js, npm, and Angular CLI
  user_data = <<-EOF
  #!/bin/bash

  # Update system
  sudo apt update -y

  # Install Node.js 20.x and npm
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs

  # Install npm (if not already installed with Node.js)
  sudo apt install -y npm

  # Install Angular CLI globally
  sudo npm install -g @angular/cli@20.3.7

  EOF

  tags = {
    Name = "usermgmtfe"
  }
}

# Output the public IP address of the EC2 instance
output "usermgmtfe_public_ip" {
  value = aws_instance.usermgmtfe.public_ip
}

resource "aws_instance" "usermgmtdb" {
  ami = "ami-0290e60ec230db1e4"  # Make sure this AMI has MySQL or is a base Linux AMI
  instance_type = "t3.medium"
  
  security_groups = [aws_security_group.usermgmtdb_sg.name]
  
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
