import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
import numpy as np
import cv2
import time

# --- KERNEL CUDA (Lógica propia de convolución) ---
mod = SourceModule("""
__global__ void kernelConvolucion(unsigned char *in, unsigned char *out, int w, int h, int mask_size) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int offset = mask_size / 2;
        float sum = 0.0f;
        float norm_factor = 1.0f / (float)(mask_size * mask_size);

        for (int ky = -offset; ky <= offset; ky++) {
            for (int kx = -offset; kx <= offset; kx++) {
                int py = min(max(y + ky, 0), h - 1);
                int px = min(max(x + kx, 0), w - 1);
                sum += (float)in[py * w + px];
            }
        }
        out[y * w + x] = (unsigned char)(sum * norm_factor);
    }
}
""")

kernel = mod.get_function("kernelConvolucion")

def ejecutar_practica():
    # 1. Cargar imagen original (6000x6000 sugerido) [cite: 65, 86]
    path = "WhatsApp Image 2026-05-04 at 16.40.15-6000x6000.jpg.jpeg" 
    img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        print("Error: No se encontró la imagen 'entrada.jpg'")
        return

    h, w = img.shape
    mask_sizes = [15, 150, 350] # Las 3 máscaras solicitadas [cite: 87]
    p = 256 # Núcleos CUDA de tu MX230

    print(f"Iniciando Práctica - Imagen: {w}x{h} | Hilos GPU: {p}")
    print("-" * 50)

    for size in mask_sizes:
        print(f"EJECUTANDO MÁSCARA: {size}x{size}")
        
        # --- FASE GPU (PARALELO) ---
        img_gpu = cuda.mem_alloc(img.nbytes)
        res_gpu_mem = cuda.mem_alloc(img.nbytes)
        cuda.memcpy_htod(img_gpu, img)

        block = (16, 16, 1)
        grid = (int(np.ceil(w/16)), int(np.ceil(h/16)))

        start_p = time.time()
        kernel(img_gpu, res_gpu_mem, np.int32(w), np.int32(h), np.int32(size), block=block, grid=grid)
        cuda.Context.synchronize()
        tp = time.time() - start_p

        res_gpu_img = np.empty_like(img)
        cuda.memcpy_dtoh(res_gpu_img, res_gpu_mem)
        cv2.imwrite(f"res_gpu_{size}.jpg", res_gpu_img)

        # --- FASE CPU (SECUENCIAL) ---
        # Implementación manual con NumPy para validez académica
        start_s = time.time()
        offset = size // 2
        # Padding para evitar errores de borde en CPU
        img_padded = np.pad(img, offset, mode='edge')
        res_cpu_img = np.zeros_like(img)

        # Optimizamos con strides de numpy para que no tarde horas, 
        # pero manteniendo la lógica de promediado de ventana.
        for y in range(h):
            for x in range(w):
                ventana = img_padded[y : y + size, x : x + size]
                res_cpu_img[y, x] = np.mean(ventana)
        
        ts = time.time() - start_s
        cv2.imwrite(f"res_cpu_{size}.jpg", res_cpu_img)

        # --- CÁLCULO DE MÉTRICAS [cite: 17, 98] ---
        S = ts / tp
        E = S / p

        print(f"RESULTADOS {size}x{size}:")
        print(f"  Ts (Secuencial): {ts:.4f} s")
        print(f"  Tp (Paralelo):   {tp:.4f} s")
        print(f"  Aceleramiento (S): {S:.2f}")
        print(f"  Eficiencia (E):    {E:.4f}")
        print("-" * 50)

if __name__ == "__main__":
    ejecutar_practica()