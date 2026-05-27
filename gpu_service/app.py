from flask import Flask, request, jsonify, send_file
import cupy as cp
import cv2
import numpy as np
import os
import time

app = Flask(__name__)

# Directorio temporal para guardar los resultados procesados en la PC
UPLOAD_FOLDER = "processed_images"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# 🎯 CATÁLOGO UNIFICADO: Mapea los filtros oficiales exigidos por tu rúbrica SQL
MASCARAS_MASTER = {
    "CONVOLUCION_MANUAL": ["15x15", "150x150", "350x350"],
    "HIGH_BOOST": ["25x25", "71x71", "141x141"] # 🚀 Tu nuevo filtro estrella
}

# ==============================================================================
# 🔥 KERNELS CUDA EN CUPY (Arquitectura en Paralelo Pura)
# ==============================================================================

# Kernel 1: Convolución Estándar (Promedio/Blur)
convolucion_kernel = cp.RawKernel(r'''
extern "C" __global__ 
void kernelConvolucion(const unsigned char* in, unsigned char* out, int w, int h, int mask_size) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int offset = mask_size / 2;
        float sum = 0.0f;
        float norm_factor = 1.0f / (float)(mask_size * mask_size);

        for (int ky = -offset; ky <= offset; ky++) {
            for (int kx = -offset; kx <= offset; kx++) {
                int py = max(0, min(y + ky, h - 1));
                int px = max(0, min(x + kx, w - 1));
                sum += (float)in[py * w + px];
            }
        }
        out[y * w + x] = (unsigned char)(sum * norm_factor);
    }
}
''', 'kernelConvolucion')


# Kernel 2: High-Boost Inteligente (Filtro Dinámico de Alta Amplificación)
high_boost_kernel = cp.RawKernel(r'''
extern "C" __global__
void kernelHighBoost(const unsigned char* in, unsigned char* out, const float* kernel, int w, int h, int mask_size) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int offset = mask_size / 2;

    if (x < w && y < h) {
        // Manejo estricto de bordes según la lógica del enunciado
        if (x >= offset && y >= offset && x < w - offset && y < h - offset) {
            float suma = 0.0f;

            for (int ky = -offset; ky <= offset; ky++) {
                for (int kx = -offset; kx <= offset; kx++) {
                    float pixel = (float)in[(y + ky) * w + (x + kx)];
                    float valor_kernel = kernel[(ky + offset) * mask_size + (kx + offset)];
                    suma += pixel * valor_kernel;
                }
            }
            
            // Clamping atómico (0 - 255) nativo en GPU
            out[y * w + x] = (unsigned char)max(0.0f, min(suma, 255.0f));
        } else {
            // Mantener el píxel original intacto en las fronteras de la máscara
            out[y * w + x] = in[y * w + x];
        }
    }
}
''', 'kernelHighBoost')

# ==============================================================================
# 🛰️ ENDPOINTS DE LA API REST
# ==============================================================================

@app.route('/api/pycuda/filters', methods=['GET'])
def get_available_filters():
    return jsonify(MASCARAS_MASTER), 200

@app.route('/api/pycuda/apply-filter', methods=['POST'])
def apply_filter():
    try:
        if 'image' not in request.files:
            return jsonify({"status": "FAILED", "error": "Falta el archivo de imagen"}), 400
        
        file = request.files['image']
        filtro = request.form.get('filter', 'CONVOLUCION_MANUAL')
        mascara_str = request.form.get('mask_size', '15x15')
        mask_size = int(mascara_str.split('x')[0])

        # 1. Decodificar la imagen en escala de grises vía OpenCV
        file_bytes = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(file_bytes, cv2.IMREAD_GRAYSCALE)
        h, w = img.shape

        print(f"🔥 Modo GPU Activo: [{filtro}] | Dimensión: {w}x{h} | Máscara: {mask_size}x{mask_size}")

        # 2. Alojar matrices en la VRAM de la GeForce
        img_gpu = cp.array(img, dtype=cp.uint8)
        res_gpu = cp.empty_like(img_gpu)

        # 3. Mapear la Arquitectura de Grid e Hilos (Bloques de 16x16)
        block_dim = (16, 16)
        grid_dim = (int((w + 15) // 16), int((h + 15) // 16))
        total_threads = int(grid_dim[0] * 16 * grid_dim[1] * 16)

        # 4. Orquestación y ejecución de Kernels según el Filtro Seleccionado
        start_time = time.time()
        
        if filtro == "HIGH_BOOST":
            # Generar la matriz matemática del High-Boost directamente en la GPU
            kernel_hb = cp.full((mask_size, mask_size), -1.0 / (mask_size * mask_size), dtype=cp.float32)
            centro = mask_size // 2
            kernel_hb[centro, centro] = 2.0  # Factor de amplificación A = 2
            
            # Lanzamos el kernel dedicado pasándole la matriz del filtro en VRAM
            high_boost_kernel(grid_dim, block_dim, (img_gpu, res_gpu, kernel_hb, w, h, mask_size))
        else:
            # Filtro por defecto: Convolución manual estándar
            convolucion_kernel(grid_dim, block_dim, (img_gpu, res_gpu, w, h, mask_size))

        cp.cuda.Stream.null.synchronize()
        end_time = time.time()

        kernel_time_ms = (end_time - start_time) * 1000.0

        # 5. Descargar el resultado procesado a la RAM del Host
        res_cpu_img = res_gpu.get()
        
        output_filename = f"result_{int(time.time())}_{mask_size}.jpg"
        output_path = os.path.join(UPLOAD_FOLDER, output_filename)
        cv2.imwrite(output_path, res_cpu_img)

        # Retorna el mismo JSON exacto que tu Java WebFlux ya sabe leer
        return jsonify({
            "status": "COMPLETED",
            "processedPath": output_path,
            "imageWidth": w,
            "imageHeight": h,
            "blockDimX": 16,
            "blockDimY": 16,
            "gridDimX": grid_dim[0],
            "gridDimY": grid_dim[1],
            "totalThreadsLaunched": total_threads,
            "kernelTimeMs": round(kernel_time_ms, 4)
        }), 200

    except Exception as e:
        print(f"❌ Error crítico en clúster CUDA: {str(e)}")
        return jsonify({"status": "FAILED", "error": str(e)}), 500

@app.route('/api/pycuda/download', methods=['GET'])
def download_file():
    path = request.args.get('path')
    if path and os.path.exists(path):
        return send_file(path, mimetype="image/jpeg")
    return jsonify({"error": "Archivo no encontrado"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)