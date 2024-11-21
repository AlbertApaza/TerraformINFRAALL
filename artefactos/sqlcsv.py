import re
import csv
import os

input_dir = "data"
output_file = "datos_combinados.csv"

insert_regex = re.compile(
    r"INSERT INTO `trafico_red`.*?VALUES\s*(\(.*?\));", re.DOTALL
)

headers = [
    "id", "fecha", "ip", "clase", "horario", "dia", "turno", "laboratorio",
    "total_enviado_mb", "total_recibido_mb", "tema", "navegador", "seccion",
    "docente", "total_mbps", "total_GB", "tiempo_sesion", "consumo_energia_kwh"
]

all_data_rows = []

for file_name in os.listdir(input_dir):
    if file_name.endswith(".sql"):
        file_path = os.path.join(input_dir, file_name)
        print(f"Procesando archivo: {file_name}")
        with open(file_path, "r", encoding="utf-8") as file:
            sql_content = file.read()
        
        matches = insert_regex.findall(sql_content)
        
        for match in matches:
            rows = match.strip().strip(";").split("),")
            for row in rows:
                row = row.strip() + ")" if not row.endswith(")") else row
                values = re.split(r",\s*(?=(?:[^']*'[^']*')*[^']*$)", row.strip("()"))
                clean_values = [v.strip().strip("'") if v.strip() != "NULL" else "" for v in values]
                all_data_rows.append(clean_values)

with open(output_file, "w", newline="", encoding="utf-8") as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(headers)
    writer.writerows(all_data_rows)

print(f"Archivo CSV generado exitosamente: {output_file}")
