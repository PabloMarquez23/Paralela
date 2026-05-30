# 🎯 CAMBIO CRÍTICO: Usamos 'runtime' en lugar de 'base' para incluir libnvrtc y el Toolkit de CUDA
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

# Evitar interrupciones de zona horaria durante la instalación de paquetes
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias del sistema para Python, OpenCV y CUDA
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar requerimientos e instalar dependencias de Python
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 🎯 ENLACE DE SEGURIDAD: Ahora que la librería sí existe por usar 'runtime', 
# creamos el enlace simbólico exacto que busca CuPy en su versión 12
RUN ln -s /usr/local/cuda/lib64/libnvrtc.so /usr/local/cuda/lib64/libnvrtc.so.12 || true

# Copiar el código de Flask y los recursos institucionales (logos, marcos, etc.)
COPY . .

EXPOSE 5000

# Asegurar que los prints de Python se muestren inmediatamente en los logs de Docker
ENV PYTHONUNBUFFERED=1

CMD ["python3", "app.py"]