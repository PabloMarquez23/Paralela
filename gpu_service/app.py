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

# 🎯 CATÁLOGO REAL: Refleja exactamente tu práctica académica con CuPy
MASCARAS_MASTER = {
    "CONVOLUCION_MANUAL": ["15x15", "150x150", "350x350"]
}

# --- KERNEL CUDA EN CUPY (Tu lógica exacta de convolución) ---
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

        # 1. Leer los bytes de la imagen y decodificarla en escala de grises con OpenCV
        file_bytes = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(file_bytes, cv2.IMREAD_GRAYSCALE)
        h, w = img.shape

        print(f"🔥 Procesando en GPU: {w}x{h} | Máscara CUDA: {mask_size}x{mask_size}")

        # 2. Subir la matriz Host (CPU) al Device (GPU VRAM) usando CuPy
        img_gpu = cp.array(img, dtype=cp.uint8)
        res_gpu = cp.empty_like(img_gpu)

        # 3. Configuración de la Arquitectura de Hilos (Bloques estándar de 16x16)
        block_dim = (16, 16)
        grid_dim = (int((w + 15) // 16), int((h + 15) // 16))
        total_threads = int(grid_dim[0] * 16 * grid_dim[1] * 16)

        # 4. Lanzar el Kernel CUDA y Sincronizar el Contexto de Hardware
        start_time = time.time()
        convolucion_kernel(grid_dim, block_dim, (img_gpu, res_gpu, w, h, mask_size))
        cp.cuda.Stream.null.synchronize()
        end_time = time.time()

        kernel_time_ms = (end_time - start_time) * 1000.0

        # 5. Descargar el resultado de la VRAM a la RAM y guardar archivo de salida
        res_cpu_img = res_gpu.get()
        
        output_filename = f"result_{int(time.time())}_{mask_size}.jpg"
        output_path = os.path.join(UPLOAD_FOLDER, output_filename)
        cv2.imwrite(output_path, res_cpu_img)

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
        print(f"❌ Error en clúster CUDA: {str(e)}")
        return jsonify({"status": "FAILED", "error": str(e)}), 500

@app.route('/api/pycuda/download', methods=['GET'])
def download_file():
    path = request.args.get('path')
    if path and os.path.exists(path):
        # 🎯 CORREGIDO: Usamos mimetype sin guion bajo para evitar excepciones 500
        return send_file(path, mimetype="image/jpeg")
    return jsonify({"error": "Archivo no encontrado"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)