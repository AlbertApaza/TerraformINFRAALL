provider "aws" {
  region = "us-east-1"
}

# Crear una VPC
resource "aws_vpc" "vpc_negocios" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_negocios"
  }
}

# Crear subredes en diferentes zonas de disponibilidad
resource "aws_subnet" "subnets" {
  count                   = 6
  vpc_id                  = aws_vpc.vpc_negocios.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = element(["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-${count.index + 1}"
  }
}

# Crear un Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_negocios.id
  tags = {
    Name = "igw_negocios"
  }
}

# Crear tabla de enrutamiento y asociarla al IGW
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc_negocios.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route_table_negocios"
  }
}

# Asociar tabla de enrutamiento a las subredes
resource "aws_route_table_association" "route_associations" {
  count          = 6
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.route_table.id
}

# Crear un bucket S3
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "netuptinteligencianegocios"
  tags = {
    Name = "S3 Bucket Inteligencia Negocios"
  }
}

# Crear la base de datos en AWS Glue Data Catalog
resource "aws_glue_catalog_database" "albertapaza_database" {
  name        = "tb_redupt_database"
  description = "Base de datos para almacenar tablas de inteligencia de negocios"
}


# Crear un Crawler de AWS Glue
resource "aws_glue_crawler" "netuptinteligencianegocios_crawler" {
  name          = "netuptinteligencianegocios-crawler"
  role          = "arn:aws:iam::183789758787:role/LabRole"
  database_name = aws_glue_catalog_database.albertapaza_database.name

  s3_target {
    path = "s3://netuptinteligencianegocios/"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = {
    Name = "Glue Crawler Inteligencia Negocios"
  }

  depends_on = [aws_s3_bucket.s3_bucket] # Asegura que el bucket S3 sea creado antes del Crawler
}


#gets id
#2 aws glue get-crawler --name netuptinteligencianegocios-crawler
#0 subir ejecutar ecript pythonde subir csv
#aws glue get-crawler --name netuptinteligencianegocios-crawler
#aws glue get-databases






#pasos 
#terraform apply --auto-approve (si es primera vez)
    #si no, limpiar el bucket
        #aws s3 rm s3://netuptinteligencianegocios --recursive
        #aws glue delete-crawler --name netuptinteligencianegocios-crawler

#ejecutar python "s3bucket.py"
#aws glue start-crawler --name netuptinteligencianegocios-crawler
    #esperar 2 minutos  a lo mucho aunque depende de los datos
#aws glue get-table --database-name tb_redupt_database --name netuptinteligencianegocios
