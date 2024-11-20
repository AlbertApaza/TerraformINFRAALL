import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

s3 = boto3.client('s3', region_name='us-east-1')

file_path = 'machine-readable-business-employment-data-Jun-2024-quarter.csv'
bucket_name = 'netuptinteligencianegocios'
object_name = 'machine-readable-business-employment-data-Jun-2024-quarter.csv'

try:
    s3.upload_file(file_path, bucket_name, object_name)
    print(f'Archivo {file_path} cargado con éxito a S3://{bucket_name}/{object_name}')
except FileNotFoundError:
    print(f'El archivo {file_path} no fue encontrado.')
except NoCredentialsError:
    print('No se encontraron credenciales de AWS.')
except PartialCredentialsError:
    print('Credenciales de AWS incompletas.')
except Exception as e:
    print(f'Ocurrió un error: {e}')
