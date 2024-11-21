provider "aws" {
  region = "us-east-1"
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
  role          = "arn:aws:iam::183789758787:role/LabRole"  # Usar el rol existente
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

# Crear la función Lambda
resource "aws_lambda_function" "s3_upload_lambda" {
  filename         = "../artefactos/lambda_function.zip"  # Ruta relativa al archivo ZIP de la función Lambda
  function_name    = "s3-upload-function"
  role             = "arn:aws:iam::183789758787:role/LabRole"  # Usar el rol existente
  handler          = "s3bucket.lambda_handler"  # El nombre de la función de entrada del código Python
  runtime          = "python3.8"  # Runtime Python 3.8
  timeout          = 30
  memory_size      = 128
  source_code_hash = filebase64sha256("../artefactos/lambda_function.zip")  # Hash del archivo ZIP

  environment {
    variables = {
      BUCKET_NAME = "netuptinteligencianegocios"
    }
  }
}


# Crear un evento en S3 para activar la función Lambda
resource "aws_s3_bucket_notification" "s3_event_to_lambda" {
  bucket = aws_s3_bucket.s3_bucket.bucket

  lambda_function {
    events             = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.s3_upload_lambda.arn
  }

  depends_on = [aws_lambda_function.s3_upload_lambda]
}

# Dar permiso a S3 para invocar la función Lambda
resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_upload_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_bucket.arn
}

#gets id
#2 aws glue get-crawler --name netuptinteligencianegocios-crawler
#0 subir ejecutar ecript pythonde subir csv
#aws glue get-crawler --name netuptinteligencianegocios-crawler
#aws glue get-databases




#pasos eliminar
#aws s3 rm s3://netuptinteligencianegocios --recursive

#pasos iniciar
#terraform apply --auto-approve (si es primera vez)
    #si no, limpiar el bucket
        #aws s3 rm s3://netuptinteligencianegocios --recursive
        #aws glue delete-crawler --name netuptinteligencianegocios-crawler

#ejecutar lambda
#aws lambda invoke --function-name s3-upload-function --payload '{}' output.txt

#aws glue start-crawler --name netuptinteligencianegocios-crawler
    #esperar 2 minutos  a lo mucho aunque depende de los datos
#aws glue get-table --database-name tb_redupt_database --name netuptinteligencianegocios
