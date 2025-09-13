#Proyecto Data Mining 1-John Ochoa

Mage y Postgres se comunican por nombre de servicio. SI

Todos los secretos (QBO y Postgres) están en Mage Secrets; no hay secretos en el
repo/entorno expuesto. SI

Pipelines qb_<entidad>_backfill acepta fecha_inicio y fecha_fin (UTC) y
segmenta el rango. SI

Trigger one-time configurado, ejecutado y luego deshabilitado/marcado como
completado. SI

Esquema raw con tablas por entidad, payload completo y metadatos obligatorios. SI

Idempotencia verificada: reejecución de un tramo no genera duplicados. SI

Paginación y rate limits manejados y documentados. SI

Volumetría y validaciones mínimas registradas y archivadas como evidencia. SI

Runbook de reanudación y reintentos disponible y seguido. SI


QBO Backfill Pipelines para Curso Data Mining – Mage + Docker Compose + Postgres

1. Descripción

Este proyecto del curso de Data Mining se encarga de implementar pipelines de backfill histórico para sincronizar datos desde QuickBooks Online (QBO) que es una herramienta para desarrollo de aplicaciones de Intuit con datos de gestión de una empresa (facturas,clientes,items,etc) hacia Postgres bajo el esquema raw. Todo esto se despliega mediante Docker Compose con un script que levantará 3 contenedores que corresponden a: Postgres, pgAdmin y Mage interconectados por una red interna de modo que todos los servicios puedan comunicarse entre si. El Pgadmin servirá como administrador de la base de datos, el Postgresql será el sistema de gestión de base de datos y por último el Mage que fungirá como orquestador a través de pipelines que ejecutarán procesos de flujo DataLoader->Transform->DataExporter a manera de poder extraer los datos desde QBO y depositarlos en tablas raw de nuestro schema en Postgresql para las entidades customers, invoices y Items. Cada pipeline maneja idempotencia, segmentación temporal, paginación y reintentos automáticos. Además se tienen one-time triggers para gestionnar la ejecución de cada pipeline acorde a zonas horarias UTC y America/Guayaquil. Posterior a la ejecución existosa se desactiva el trigger y con eso se completa el flujo.

2. Arquitectura

            ┌──────────────────┐
            │   QuickBooks     │
            │ (API OAuth2)     │
            └────────┬─────────┘
                     │
                     │ Extracción
                     ▼
            ┌──────────────────┐
            │   Mage           │
            │ (Pipeline)       │
            └────────┬─────────┘
                     │ Carga
                     ▼
          ┌──────────────────────┐
          │   PostgreSQL (BBDD)  │
          │   raw                │
          │                      │
          └─────────┬────────────┘
                    │
                    ▼
          ┌──────────────────────┐
          │   pgAdmin            │
          │ (Gestión DB)         │
          └──────────────────────┘

3. Pasos para levantar contenedores y configurar el proyecto

3.1. Tener Docker configurado en la PC
3.2. Generar un directorio donde almacenar el proyecto
3.3. Colocar dentro del directorio el docker-compose.yml con los datos de despliegue de contenedores Postgresql + PgAdmin + Mage
3.4. Establecer red de comunicación en docker-compose.yml para interacción entre servicios
3.4. Levantar contenedores
3.5. Probar conexión y correcto despliegue ingresando en localhost a los puertos adecuados para Mage, PgAdmin, Postgresql

4. Gestión de secretos (nombres, propósito, rotación, responsables; sin valores).

POSTGRES_HOST nombre del host de la base de datos- Responsable Admin DB
POSTGRES_DB nombre del schema de la base de datos- Responsable Admin DB
POSTGRES_USER nombre del usuario de conexion con la base de datos- Responsable Admin DB
POSTGRES_PASSWORD password del usuario para la conexion con la base de datos-Responsable Admin DB
QBO_CLIENT_ID identificador público de tu aplicación registrada en el portal de desarrolladores de QBO
QBO_CLIENT_SECRET clave privada para interacción con la aplicación de QBO
QBO_REALM_ID id de la empresa registrada en QBO para obtención de sus datos
QBO_REFRESH_TOKEN token que entrega QBO para pedir nuevos access tokens con los cuales comunicarse via API
QBO_ENV ambiente de la aplicacion de QBO- Responsable Admin Aplicación

5. Detalle de los tres pipelines qb_<entidad>_backfill: parámetros, segmentación, límites, reintentos, runbook.

qb_<entidad>_backfill: 
parametros: fecha_fin, fecha_inicio, page_number, page_size, table_name_invoices
segmentación: dataloader, transformer, exporter
límites: 
La segmentación se realiza por fecha. Cada request trae un máximo de page_size registros definido en el pipeline. Se usa paginación para recorrer todas las páginas.
reintentos:
Cada request HTTP implementa timeout y reintento automático
Runbook de ejecución:
1. Verificar que los contenedores estén activos
2. Verificar que las variables, secrets y el pipeline estén listos
3. Ejecutar el trigger y verificar su ejecución correcta
4. Verificar idempotencia accediendo a tabla de Postgresql

6. Trigger one-time: fecha/hora en UTC y equivalencia a Guayaquil; política de deshabilitación post-ejecución.

Se define como estándar una ejecución de los pipeline a las 23:59 horario UTC que es el horario estándar del Batch y -5 horas correspondería a Guayaquil por lo que aquello equivaldría a las 18:59 horario America/Guayaquil

Se ha implementado la política de desactivación del trigger pos-ejecución de los pipeline

7. Esquema raw: tablas por entidad, claves, metadatos obligatorios, idempotencia

Tablas por entidad: 
raw.qb_invoices: Facturas extraídas desde QBO
raw.qb_customers: Clientes extraídos desde QBO
raw.qb_items: Items extraídos desde QBO

Claves:
Cada tabla tiene id PRIMARY KEY

Datos y metadatos: 

payload: JSON completo de la entidad desde QBO
ingested_at_utc: Fecha y hora de ingestión en UTC
extract_window_start_utc: Inicio de la ventana de extracción
extract_window_end_utc: Fin de la ventana de extracción
page_number: Número de página procesada en la paginación QBO
page_size: Tamaño de página procesada
request_payload: Payload enviado en la request, para trazabilidad
source_realm_id: Realm ID de QBO origen (empresa)
source_env: Entorno de Aplicación

Idempotencia:
Las inserciones duplicadas se actualizan ON CONFLICT UPDATE

8. Validaciones/volumetría

Cómo correr las validaciones

8.1. Acceder al contenedor de MageAI o al entorno de ejecución local donde se definió el pipeline.
8.2. Ejecutar los bloques de validación del pipeline
8.3. Conteo de registros por ventana de extracción.
8.4. Comparación de volúmenes entre páginas de paginación y comparación de volumetría contra data de QBO

Como saber si esta todo bien: 
Conteos correctos: La cantidad de registros coincide con los datos de la fuente.
Discrepancias en volumen: Indican posibles fallas en la paginación.
Errores de formato o JSON: Señalan que algún payload no cumple con la estructura esperada.

9. Troubleshooting

Durante la ejecución de los pipelines de backfill, pueden presentarse distintos problemas:

9.1. Error 401 o token inválido al intentar conectarse a QBO. Revisar que las variables de entorno QBO_CLIENT_ID, QBO_CLIENT_SECRET, QBO_REALM_ID y QBO_REFRESH_TOKEN estén correctamente configuradas.
9.2. Paginación y límites de API. Falta de registros o cargas incompletas. La API de QBO limita el número de resultados.
9.3. Problemas con Timezones y fechas: Registros fuera de la ventana esperada o duplicados. Diferencias entre UTC y la zona horaria de referencia (Guayaquil). Configurar las fechas de extracción en UTC en los triggers.
9.4. Error con BBDD: El usuario de PostgreSQL no tiene permisos para la tabla o esquema raw.

Reintentos y backoff

Para cualquier fallo temporal (timeout, error de conexión), los pipelines se pueden dar clic para reintento manual


2. Definiciones del proyecto de Mage y de las pipelines qb_<entidad>_backfill con su trigger one-time.

En la carpeta scripts se encuentran todos los códigos de Python para dataloader, transformers y exportes de cada uno de los 3 pipelines y la configuración y detalle de los triggers se puede observar en las capturas adjuntas en la carpeta de evidencias

3. Definiciones de base de datos para raw (tablas y restricciones) claramente documentadas.

La generación del schema se puede observar dentro de la carpeta init-scripts en el script crearTablas.sql y el detalle de toda la base de datos para raw igual se describe en el presente README en la sección de esquema raw

4. Pruebas/validaciones de calidad y guía para ejecutarlas

Prueba de levantamiento de contenedores: 
1. Se levantan los contenedores con el script de docker-compose
2. Se revisa en el Docker Desktop que este corriendo el contenedor (validacion)
3. Se revisa con docker ps en terminal que los contenedores esten activos (validacion)
4. Se ingresa a local host + puerto definido para algun servicio y se valida correcta conexión ejemplo http://localhost:6789/ (validación)

Prueba de conexión con base de datos:
1. Se ve que el servicio de postgresql este corriendo tras levantar con docker-compose
2. Se ingresa a la terminal del contenedor de postgresql y se lanza comando psql con user y db para ingresar a base
3. Se valida correcto ingreso a base de datos que salga prompt para ingresar queries (validación)
4. Se ejecutan queries para ver schemas y tablas activas para validar que se haya creado todo bien (validación)

Prueba de pipeline backfill:
1. Se ejecuta únicamente código de conexión a API para validar que estén funcionando las credenciales (validación)
2. Se ejecuta el dataloader y se observan los datos traídos desde QBO (validación)
3. Se ejecuta el transformer y se imprimen datos de pruebas de los metadatos generados (validación)
4. Se ejecuta el exporter y se valida ejecutando queries en la conexión con la base que los datos raw+id+metadatos se hayan ingresado correctamente en las tablas respectivas (validación)

Prueba de ejecución correcta de trigger:
1. Se prueba ejecutar manualmente con el trigger y se observar logs generados en Mage (validación)
2. Se prueba a definir un horario cualquiera y esperar a que suceda para validar igual correcta ejecución con logs del pipeline (validación)
3. Se verifica que tras la correcta ejecución con trigger el mismo sea desactivado automáticamente (validación)