FROM nvidia/cuda:13.0.0-devel-ubuntu24.04

# Instalamos dependencias del sistema y limpiamos caché
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends build-essential python3-pip python3-dev && \
    rm -rf /var/lib/apt/lists/*

# AGREGAMOS NUMPY AQUÍ:
RUN pip3 install --no-cache-dir --break-system-packages numpy pycuda flask

# Copiamos el código de la app
WORKDIR /app
COPY . /app

EXPOSE 5000

CMD ["python3", "./app.py"]