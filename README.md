# UPSGlam 3.0 - Sistema Integrado de Procesamiento de Imágenes en GPU y Red Social Reactiva

## 1. Descripción General del Proyecto

UPSGlam 3.0 es una plataforma social distribuida y reactiva para la gestión, publicación y procesamiento adaptativo de imágenes digitales en hardware paralelo. El ecosistema permite a los usuarios autenticarse, cargar archivos multimedia, aplicar filtros basados en matrices de convolución acelerados por hardware mediante núcleos CUDA, almacenar los resultados de manera persistente e interactuar mediante un flujo social de publicaciones, comentarios y reacciones.

El proyecto está diseñado bajo una arquitectura de microservicios contenerizados, acoplando un cliente móvil de alto rendimiento, un backend síncrono no bloqueante y un clúster dedicado de cómputo GPU que registra telemetría de hardware en tiempo real.

---

## 2. Arquitectura de Software del Sistema

El ecosistema está compuesto por los siguientes módulos interconectados de forma síncrona y asíncrona:

* **Capa de Presentación (App Móvil):** Desarrollada en Flutter, responsable de la captura multimedia, renderizado del feed global, gestión de perfiles e interactividad social.
* **Capa de Orquestación Backend (Spring WebFlux):** API reactiva no bloqueante construida sobre Java 21 que centraliza la lógica de negocio, gestiona el acceso relacional mediante R2DBC y actúa como pasarela de comunicación hacia el motor de cómputo.
* **Capa de Cómputo e Inteligencia GPU (Flask + CuPy):** Microservicio dedicado que encapsula kernels nativos de CUDA ejecutados de forma paralela en la tarjeta de video a través de bloques e hilos optimizados.
* **Infraestructura en la Nube (Supabase Ecosystem):**
* **Supabase Auth:** Control de acceso y tokens JWT.
* **Supabase Storage:** Almacenamiento distribuido de buckets (`original-images` y `processed-images`).
* **Supabase PostgreSQL:** Motor relacional para persistencia de perfiles, métricas de hardware y grafos sociales.



---

## 3. Catálogo de Filtros CUDA Implementados

El servicio de cómputo en la GPU expone 8 filtros máster optimizados de forma matemática y adaptativa según la resolución de la imagen entrante:

### Filtros Históricos (Prácticas Anteriores)

1. **CONVOLUCION_MANUAL (Box Blur):** Difuminado uniforme basado en matrices de vecindad con normalización flotante en hardware.
2. **HIGH_BOOST:** Realce de altas frecuencias espaciales mediante la amplificación balanceada del píxel central frente al entorno convolutivo.
3. **EMBOSS:** Filtro de relieve que calcula las diferencias vectoriales de intensidad lumínica a través de desplazamientos de diagonales en el kernel.

### Filtros Nuevos e Identidad Institucional

4. **SHARPNESS:** Incremento de nitidez ejecutando máscaras Laplacianas de segundo orden con factor de potencia variable.
5. **GRAYSCALE_GPU (Bifásico de Alto Contraste):** Transformación de luminancia paralela con inversión espacial según la mitad geométrica del ancho de la imagen.
6. **PIXELADO:** Filtro de censura y estilización en bloque de hardware (`8px`, `16px`, `32px`) calculado de forma matemática en el kernel.
7. **IDENTITY_UPS (Filtro Premium):** Duotono puro basado en los colores institucionales (Azul y Oro) que inyecta dinámicamente marcas de agua en memoria de video de San Juan Bosco y el logotipo oficial.
8. **CR7_FRAME:** Re-mapeo y escalado geométrico matricial en GPU que incrusta la fotografía del usuario dentro de un lienzo de canvas exterior.

---

## 4. Configuración del Entorno de Supabase (Base de Datos)

Para inicializar la persistencia de datos, ejecute el siguiente script SQL en el editor de Supabase para estructurar las tablas relacionales y los esquemas maestros:

```sql
-- Estructura de Filtros Disponibles
CREATE TABLE public.filters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    kernel_name VARCHAR(100) UNIQUE NOT NULL
);

-- Historial de Métricas de Cómputo en GPU
CREATE TABLE public.gpu_metrics (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    filter_id UUID NOT NULL REFERENCES public.filters(id),
    original_image_url TEXT NOT NULL,
    processed_image_url TEXT NOT NULL,
    image_width INT NOT NULL,
    image_height INT NOT NULL,
    block_dim_x INT NOT NULL,
    block_dim_y INT NOT NULL,
    grid_dim_x INT NOT NULL,
    grid_dim_y INT NOT NULL,
    total_threads_launched BIGINT NOT NULL,
    kernel_time_ms DOUBLE PRECISION NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

-- Inserción de Datos Maestros
INSERT INTO public.filters (name, kernel_name) VALUES 
('Convolución Manual', 'CONVOLUCION_MANUAL'),
('High Boost', 'HIGH_BOOST'),
('Emboss', 'EMBOSS'),
('Sharpness', 'SHARPNESS'),
('Grayscale GPU', 'GRAYSCALE_GPU'),
('Pixelado', 'PIXELADO'),
('Identity UPS', 'IDENTITY_UPS'),
('CR7 Frame', 'CR7_FRAME');

```

---

## 5. Configuración del Archivo de Entorno (`.env.example`)

El proyecto utiliza un esquema de inyección dinámica de credenciales para aislar las claves maestras de persistencia del código fuente. En la raíz del proyecto se incluye el archivo `.env.example`, el cual sirve como plantilla para el despliegue.

### Estructura de Variables Requeridas

```text
# Configuración de Base de Datos Reactiva R2DBC (Supabase Pooler)
SPRING_R2DBC_URL=r2dbc:postgresql://tu-pooler-url:5432/postgres?sslMode=require
SPRING_DATABASE_USERNAME=tu_usuario_postgres
SPRING_DATABASE_PASSWORD=tu_contraseña_segura

# Credenciales de acceso multimedia de Supabase Cloud
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_public_key
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key

# Enlace de comunicación al clúster de hardware paralelo
FLASK_SERVER_URL=http://flaskservice:5000

```

---

## 6. Guía de Construcción, Ejecución y Despliegue Contenerizado

Siga estrictamente el siguiente protocolo técnico desde la terminal de su sistema operativo en el directorio raíz del proyecto (`PARALELA/`):

### Paso 1: Preparación del Archivo de Entorno Local

Duplique la plantilla de ejemplo y configure sus credenciales reales de Supabase (las cuales serán leídas automáticamente por Docker Compose de forma externa):

```powershell
cp .env.example .env

```

*Nota: Edite el archivo `.env` recién creado e introduzca las cadenas de conexión correspondientes a su instancia activa de Supabase.*

### Paso 2: Compilación del Artefacto Reactivo (Java JAR)

Acceda al directorio del backend y ejecute el empaquetado del binario de producción omitiendo las tareas de test unitarios para acelerar el proceso de construcción:

```powershell
cd backend
./gradlew bootJar -x test
cd ..

```

### Paso 3: Purga Completa del Entorno Docker Residual

Garantice la limpieza de redes bridge intermedias, volúmenes locales y contenedores previos ejecutando:

```powershell
docker-compose down

```

### Paso 4: Construcción de Imágenes sin Caché de Hardware

Fuerce la descarga de la imagen base `runtime` de NVIDIA y la instalación limpia de dependencias de PyCUDA y WebFlux ignorando el almacenamiento en caché del motor de Docker:

```powershell
docker-compose build --no-cache

```

### Paso 5: Levantamiento e Integración de los Servicios

Inicialice el clúster integrado dentro de la red común aislada `upsglam_net`:

```powershell
docker-compose up

```

---

## 7. Protocolo de Pruebas de Conectividad y Ejecución en Red Local

Para validar que los servicios contenerizados se encuentren operando correctamente bajo condiciones reales de uso y red, ejecute las siguientes verificaciones:

### Prueba A: Verificación de Arranque de Servicios (Logs del Sistema)

Monitoree la salida de la terminal de Docker Compose. Debe confirmar la inyección del host y el encendido de los sockets en sus respectivos puertos de escucha sin excepciones:

```text
flaskservice     | * Running on http://172.19.0.2:5000
upsglam_backend  | 🚀 Clúster Activo: Enlazando WebClient a la GPU en: http://flaskservice:5000
upsglam_backend  | Netty started on port 8080 (http)

```

### Prueba B: Test de Interconexión mediante Cliente HTTP (Postman / cURL)

Realice una petición de prueba simulando el flujo de la aplicación móvil enviando una imagen real hacia la API reactiva del backend para comprobar que el puente de red hacia la GPU procese el kernel de forma exitosa:

```powershell
curl -X POST http://localhost:8080/api/metrics/process-image \
  -F "image=@ruta_de_tu_imagen_local.jpg" \
  -F "filter=CONVOLUCION_MANUAL" \
  -F "userId=50c18c05-a920-452b-9e85-f9ae9c4584b2"

```

### Respuesta Exitosa Esperada de la GPU

El microservicio de Python compilará el código C nativo del kernel en la memoria de la tarjeta de video, registrará las métricas relacionales y responderá con un código de estado `HTTP 200 OK` conteniendo el JSON de telemetría:

```json
{
  "status": "COMPLETED",
  "processedPath": "processed_images/proc_1779643201.jpg",
  "imageWidth": 364,
  "imageHeight": 403,
  "kernelTimeMs": 1.2452,
  "appliedMask": "15x15",
  "gridDimX": 23,
  "gridDimY": 26
}

```
