from flask import Flask, request, jsonify
import os
import time
import cv2
import numpy as np
import pycuda.driver as cuda
import glob

# ==============================================================================
# 🛠️ CONFIGURACIÓN DEL COMPILADOR ESTABLE
# ==============================================================================
RUTA_MSVC_BASE = r"C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.44.35207"
CL_PATH = os.path.join(RUTA_MSVC_BASE, "bin", "Hostx64", "x64")

# ==============================================================================
# 🔥 PARCHE DE COMPILACIÓN CON COMPATIBILIDAD DINÁMICA DE ARQUITECTURA GPU
# ==============================================================================
from pycuda.compiler import SourceModule, compile_plain

old_compile_plain = compile_plain

def custom_compile_plain(source, options=None, *args, **kwargs):
    sdk_base = r"C:\Program Files (x86)\Windows Kits\10\Include"
    versiones_sdk = glob.glob(os.path.join(sdk_base, "10.*"))
    
    inc_ucrt = ""
    if versiones_sdk:
        ultima_version_sdk = sorted(versiones_sdk)[-1]
        inc_ucrt = os.path.join(ultima_version_sdk, "ucrt")

    inc_msvc = os.path.join(RUTA_MSVC_BASE, "include")

    # Inicialización del driver para detectar hardware en la compilación estática
    cuda.init()
    dispositivo = cuda.Device(0)
    cc_major, cc_minor = dispositivo.compute_capability()
    arquitectura_real = f"sm_{cc_major}{cc_minor}"
    print(f"🎯 Tarjeta gráfica detectada con arquitectura nativa: {arquitectura_real}")

    clean_options = [
        f"-arch={arquitectura_real}",
        "--allow-unsupported-compiler",
        "-ccbin", CL_PATH,
        "-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH",
        "-D_ENABLE_EXTENDED_ALIGNED_STORAGE",
        f"-I{inc_msvc}"
    ]

    if inc_ucrt and os.path.exists(inc_ucrt):
        clean_options.append(f"-I{inc_ucrt}")

    if options:
        for opt in options:
            if opt.startswith("-I"):
                clean_options.append(opt)

    print("🚀 Cargando binario compatible directamente en los núcleos CUDA...")
    return old_compile_plain(source, clean_options, *args, **kwargs)

import pycuda.compiler
pycuda.compiler.compile_plain = custom_compile_plain

# ==============================================================================
# 🎮 INICIALIZACIÓN COMPLETA DEL DISPOSITIVO Y CONTEXTO MAESTRO
# ==============================================================================
cuda.init()
dispositivo = cuda.Device(0)
# Creamos un contexto limpio compartido para el servidor
contexto_gpu = dispositivo.make_context()

# ==============================================================================
# KERNEL CUDA (Algoritmo de convolución en paralelo)
# ==============================================================================
mod = SourceModule(r"""
extern "C" {
__global__ void kernelConvolucion(
    unsigned char *in,
    unsigned char *out,
    int w,
    int h,
    int mask_size)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h)
    {
        int offset = mask_size / 2;
        float sum = 0.0f;
        float norm_factor = 1.0f / (float)(mask_size * mask_size);

        for (int ky = -offset; ky <= offset; ky++)
        {
            for (int kx = -offset; kx <= offset; kx++)
            {
                int py = min(max(y + ky, 0), h - 1);
                int px = min(max(x + kx, 0), w - 1);

                sum += (float)in[py * w + px];
            }
        }

        out[y * w + x] = (unsigned char)(sum * norm_factor);
    }
}
}
""")

print("✅ ¡LOGRADO! ¡El microservicio cargó el Kernel perfectamente en tu GPU!")
kernel = mod.get_function("kernelConvolucion")

# Liberamos el contexto del hilo principal para que los hilos de Flask lo puedan reclamar
contexto_gpu.pop()

# ==============================================================================
# FLASK MICROSERVICIO
# ==============================================================================
app = Flask(__name__)

@app.route('/process', methods=['POST'])
def process_image():
    data = request.get_json(silent=True) or {}
    if not data:
        data = request.form.to_dict() or request.args.to_dict()

    if not data:
        return jsonify({"status": "ERROR", "message": "No se recibieron datos en la peticion"}), 400

    image_path = data.get("imagePath", data.get("path", ""))
    filter_applied = data.get("filter", data.get("filterName", "GPU Filter"))

    if not image_path:
        return jsonify({"status": "ERROR", "message": "Falta la ruta de la imagen ('imagePath' o 'path')"}), 400

    mask_size = 15
    if "150" in filter_applied:
        mask_size = 150
    elif "350" in filter_applied:
        mask_size = 350

    print(f"\n📥 Solicitud entrante -> Aplicando filtro: {filter_applied}")
    print(f"📁 Ruta del recurso: {image_path}")

    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return jsonify({"status": "ERROR", "message": f"No se encontró la imagen en: {image_path}"}), 400

    h, w = img.shape

    # 🛠️ PARCHE MULTITHREADING: Forzar al hilo de la petición a entrar al contexto GPU
    contexto_gpu.push()

    try:
        block = (16, 16, 1)
        grid = (int(np.ceil(w / 16)), int(np.ceil(h / 16)))

        # Reservar memoria dedicada en la VRAM de la GPU (¡Ahora sí va a funcionar!)
        img_gpu = cuda.mem_alloc(img.nbytes)
        result_gpu = cuda.mem_alloc(img.nbytes)

        # Copiar datos CPU -> GPU
        cuda.memcpy_htod(img_gpu, img)

        start = time.time()

        # Lanzamiento del Kernel en la GPU
        kernel(
            img_gpu,
            result_gpu,
            np.int32(w),
            np.int32(h),
            np.int32(mask_size),
            block=block,
            grid=grid
        )

        cuda.Context.synchronize()
        elapsed = time.time() - start

        # Copiar de vuelta GPU -> CPU
        result_img = np.empty_like(img)
        cuda.memcpy_dtoh(result_img, result_gpu)

        output_path = image_path.replace(".jpg", "_gpu.jpg").replace(".jpeg", "_gpu.jpeg").replace(".png", "_gpu.png")
        cv2.imwrite(output_path, result_img)

        img_gpu.free()
        result_gpu.free()
        
    finally:
        # 🛠️ Liberar el contexto pase lo que pase para no dejar bloqueada la GPU
        contexto_gpu.pop()

    print(f"✅ Procesado por hardware en {round(elapsed * 1000, 2)} ms")

    return jsonify({
        "status": "SUCCESS",
        "filterName": filter_applied,
        "executionTimeMs": round(elapsed * 1000, 2),
        "outputImage": output_path,
        "imageSize": f"{w}x{h}",
        "maskSize": mask_size
    })

if __name__ == '__main__':
    print("\n🔥 GPU SERVER RUNNING - ESCUCHANDO EN EL PUERTO 5000")
    print("====================================================")
    app.run(host='0.0.0.0', port=5000, debug=False)