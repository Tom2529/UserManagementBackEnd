provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "usermgmtdb_sg" {
  name        = var.security_group_name
  description = "Security group for MySQL access and other required ports"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_instance" "usermgmtbe" {
  ami = var.ami
  instance_type = var.instance_type
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
  ami = var.ami
  instance_type = var.instance_type  
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
  ami = var.ami
  instance_type = var.instance_type  
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
