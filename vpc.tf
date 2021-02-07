resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.42.0.0/16"
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet-public-1" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.42.64.0/19"
    map_public_ip_on_launch = "true" //a public subnet
    availability_zone = "eu-west-1a"
    tags = {
        Name = "subnet-public-1"
    }
}

resource "aws_subnet" "subnet-public-2" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.42.96.0/19"
    map_public_ip_on_launch = "true" //a public subnet
    availability_zone = "eu-west-1b"
    tags = {
        Name = "subnet-public-2"
    }
}


resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main-vpc.id
    tags = {
        Name = "igw"
    }
}

resource "aws_route_table" "public-crt" {
    vpc_id = aws_vpc.main-vpc.id
    
    route {     
        cidr_block = "0.0.0.0/0"    
        gateway_id = aws_internet_gateway.igw.id    //a route table - IGW to reach internet
    }
    
    tags = {
        Name = "public-crt"
    }
}

resource "aws_route_table_association" "crt-public-subnet-1"{
    subnet_id = aws_subnet.subnet-public-1.id
    route_table_id = aws_route_table.public-crt.id
}

resource "aws_route_table_association" "crt-public-subnet-2"{
    subnet_id = aws_subnet.subnet-public-2.id
    route_table_id = aws_route_table.public-crt.id
}



##Elastic IP for NAT Gateway 1

resource "aws_eip" "elastic-ip-for-nat-gw1" {
    vpc = true
    associate_with_private_ip = "10.42.0.100"
        tags = {
            Name = "Production-EIP1"
            }
}

##Elastic IP for NAT Gateway 2

resource "aws_eip" "elastic-ip-for-nat-gw2" {
    vpc = true
    associate_with_private_ip = "10.42.32.100"
        tags = {
            Name = "Production-EIP2"
            }
}

resource "aws_nat_gateway" "ngw-sp1" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw1.id
  subnet_id     = aws_subnet.subnet-private-1.id

  tags = {
    Name = "gw NAT1"
  }
}

resource "aws_nat_gateway" "ngw-sp2" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw2.id
  subnet_id     = aws_subnet.subnet-private-2.id

  tags = {
    Name = "gw NAT2"
  }
}

resource "aws_subnet" "subnet-private-1" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.42.0.0/19"
    map_public_ip_on_launch = "false" //a private subnet
    availability_zone = "eu-west-1a"
    tags = {
        Name = "subnet-private-1"
    }
}

resource "aws_subnet" "subnet-private-2" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.42.32.0/19"
    map_public_ip_on_launch = "false" //a private subnet
    availability_zone = "eu-west-1b"
    tags = {
        Name = "subnet-private-2"
    }
}

resource "aws_route_table" "my_vpc_eu_west_1a_private" {
    vpc_id = aws_vpc.main-vpc.id

    tags = {
        Name = "This is route table for Private Subnet-1"
    }
}

resource "aws_route_table_association" "my_vpc_eu_west_1a_private" {
    subnet_id = aws_subnet.subnet-private-1.id
    route_table_id = aws_route_table.my_vpc_eu_west_1a_private.id
}


resource "aws_route_table" "my_vpc_eu_west_2b_private" {
    vpc_id = aws_vpc.main-vpc.id

    tags = {
        Name = "This is route table for Private Subnet-2"
    }
}

resource "aws_route_table_association" "my_vpc_eu_west_2b_private" {
    subnet_id = aws_subnet.subnet-private-2.id
    route_table_id = aws_route_table.my_vpc_eu_west_2b_private.id
}

resource "aws_subnet" "subnet-private-database-1" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.42.128.0/19"
    map_public_ip_on_launch = "false" //a private subnet
    availability_zone = "eu-west-1a"
    tags = {
        Name = "subnet-private-1-database"
    }
}

resource "aws_subnet" "subnet-private-database-2" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.42.160.0/19"
    map_public_ip_on_launch = "false" //a private subnet
    availability_zone = "eu-west-1b"
    tags = {
        Name = "subnet-private-2-database"
    }
}

resource "aws_route_table" "my_vpc_eu_west_1a_private-database-1" {
    vpc_id = aws_vpc.main-vpc.id

    tags = {
        Name = "This is route table for Private Subnet database 1"
    }
}

resource "aws_route_table_association" "my_vpc_eu_west_1a_private-database-1" {
    subnet_id = aws_subnet.subnet-private-database-1.id
    route_table_id = aws_route_table.my_vpc_eu_west_1a_private-database-1.id
}


resource "aws_route_table" "my_vpc_eu_west_2b_private-database-2" {
    vpc_id = aws_vpc.main-vpc.id

    tags = {
        Name = "This is route table for Private Subnet database 2"
    }
}

resource "aws_route_table_association" "my_vpc_eu_west_2b_private-database-2" {
    subnet_id = aws_subnet.subnet-private-database-2.id
    route_table_id = aws_route_table.my_vpc_eu_west_2b_private-database-2.id
}


resource "aws_instance" "bastion" {

  ami                         = "ami-07d9160fa81ccffb5"
  key_name                    = aws_key_pair.bastion_key.key_name
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  associate_public_ip_address = true
  
  subnet_id = aws_subnet.subnet-public-1.id
  
}

resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
  vpc_id = aws_vpc.main-vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "bastion_key" {
   key_name   = "my-key-pair"
   public_key = "ssh-rsa xxxx"
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}










