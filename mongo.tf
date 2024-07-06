provider "aws" {
  region  = "us-east-1"
  profile = "shindara"   # Replace with your AWS profile
}

resource "aws_instance" "mongodb" {
  ami                         = "ami-03cf127a"  # Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type
  instance_type               = "t2.micro"
  key_name                    = "shindarah"     # Replace with your SSH key name
  associate_public_ip_address = true

  tags = {
    Name = "MongoDB-Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -aG docker ec2-user

              # Install AWS CLI
              sudo yum install -y aws-cli
              
              # Configure MongoDB repo
              sudo tee /etc/yum.repos.d/mongodb-org-3.6.repo <<EOL
              [mongodb-org-3.6]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/3.6/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc
              EOL

              # Install MongoDB
              sudo yum install -y mongodb-org
              sudo service mongod start

              # Create backup script
              sudo tee /usr/local/bin/mongodb-backup.sh <<'EOFF'
              #!/bin/bash
              TIMESTAMP=$(date +%F-%H%M)
              BACKUP_DIR="/var/backups/mongodb"
              S3_BUCKET="s3://my-mongodb-backups"

              mkdir -p $BACKUP_DIR
              mongodump --out $BACKUP_DIR/mongodump-$TIMESTAMP
              tar -czf $BACKUP_DIR/mongodump-$TIMESTAMP.tar.gz -C $BACKUP_DIR mongodump-$TIMESTAMP
              aws s3 cp $BACKUP_DIR/mongodump-$TIMESTAMP.tar.gz $S3_BUCKET/mongodump-$TIMESTAMP.tar.gz

              # Clean up
              rm -rf $BACKUP_DIR/mongodump-$TIMESTAMP
              rm $BACKUP_DIR/mongodump-$TIMESTAMP.tar.gz
              EOFF

              sudo chmod +x /usr/local/bin/mongodb-backup.sh

              # Schedule backup script
              (sudo crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/mongodb-backup.sh") | sudo crontab -
              EOF
              
  # Security groups
  vpc_security_group_ids = [aws_security_group.mongodb-sg.id]
}

resource "aws_security_group" "mongodb-sg" {
  name        = "mongodb-sg"
  description = "Allow SSH and MongoDB inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ip" {
  value = aws_instance.mongodb.public_ip
}
