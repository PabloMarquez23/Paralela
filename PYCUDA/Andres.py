import numpy as np
from PIL import Image
import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
import time

# =========================================================
# CARGAR IMAGEN
# =========================================================
# Asegúrate de que el nombre coincida con tu archivo
img = Image.open("WhatsApp Image 2026-05-04 at 16.40.15-6000x6000.jpg.jpeg").convert("RGB")
img_np = np.array(img).astype(np.uint8)
height, width, channels = img_np.shape

print(f"Imagen cargada: {width}x{height}")

# =========================================================
# CUDA KERNEL (Intacto para no alterar la lógica original)
# =========================================================
mod = SourceModule("""
__global__ void convolucionGPU(
    unsigned char* input,
    unsigned char* output,
    float* kernel,
    int width,
    int height,
    int channels,
    int kSize)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int offset = kSize / 2;

    if (x >= offset && y >= offset &&
        x < width - offset &&
        y < height - offset)
    {
        float suma = 0.0;

        for(int ky = -offset; ky <= offset; ky++)
        {
            for(int kx = -offset; kx <= offset; kx++)
            {
                int pixel = input[((y + ky) * width + (x + kx)) * channels];
                float valor = kernel[(ky + offset) * kSize + (kx + offset)];
                suma += pixel * valor;
            }
        }

        int resultado = min(max((int)suma, 0), 255);

        for(int c = 0; c < channels; c++)
        {
            output[(y * width + x) * channels + c] = resultado;
        }
    }
}
""")

convolucionGPU = mod.get_function("convolucionGPU")

# =========================================================
# CONFIGURACION GPU
# =========================================================
block = (16, 16, 1)
grid = (
    (width + block[0] - 1) // block[0],
    (height + block[1] - 1) // block[1]
)
total_threads = grid[0] * grid[1] * block[0] * block[1]

print("\n--- CONFIGURACION GPU ---")
print(f"Bloques: {grid[0]} x {grid[1]}")
print(f"Hilos por bloque: {block[0]} x {block[1]}")
print(f"Total hilos: {total_threads}")

# =========================================================
# MEMORIA GPU
# =========================================================
input_gpu = cuda.mem_alloc(img_np.nbytes)
cuda.memcpy_htod(input_gpu, img_np)

mask_sizes = [25, 71, 141]

# =========================================================
# PROCESAMIENTO OPTIMIZADO
# =========================================================
for kSize in mask_sizes:
    print(f"\n========== FILTRO HIGH-BOOST {kSize}x{kSize} ==========")

    # Crear filtro High-Boost
    kernel = np.full((kSize, kSize), -1.0 / (kSize * kSize), dtype=np.float32)
    centro = kSize // 2
    kernel[centro, centro] = 2.0
    offset = kSize // 2

    # Extraemos el canal 0 (Gris/Rojo base para convolución según tu lógica)
    img_canal = img_np[:, :, 0].astype(np.float32)
    output_cpu = np.zeros_like(img_np)

# =====================================================
    # CPU - PROCESAMIENTO SECUENCIAL VECTORIZADO (MÁXIMA VELOCIDAD)
    # =====================================================
    start_cpu = time.time()

    # Acumulador matricial para evitar los ciclos for internos de la máscara
    suma_matriz = np.zeros((height, width), dtype=np.float32)

    # Corremos las ventanas de forma paralela en memoria usando operaciones vectoriales de NumPy
    for ky in range(-offset, offset + 1):
        for kx in range(-offset, offset + 1):  # <--- AQUÍ SE CORRIGIÓ EL 'in'
            valor = kernel[ky + offset, kx + offset]
            if valor != 0:
                # Desplazamiento de la matriz completa (Slicing masivo)
                suma_matriz[offset : height - offset, offset : width - offset] += (
                    img_canal[offset + ky : height - offset + ky, offset + kx : width - offset + kx] * valor
                )

    # Clamping estricto (0 - 255) vectorizado
    resultado_bloque = np.clip(suma_matriz[offset : height - offset, offset : width - offset], 0, 255).astype(np.uint8)

    # Asignación rápida a todos los canales
    for c in range(channels):
        output_cpu[offset : height - offset, offset : width - offset, c] = resultado_bloque

    end_cpu = time.time()
    cpu_time = (end_cpu - start_cpu) * 1000
    print(f"\nCPU Optimizado: {cpu_time:.2f} ms")

    # =====================================================
    # GPU - PROCESAMIENTO PARALELO (INTOCO)
    # =====================================================
    output_gpu = np.zeros_like(img_np)
    output_gpu_mem = cuda.mem_alloc(output_gpu.nbytes)
    kernel_gpu = cuda.mem_alloc(kernel.nbytes)
    cuda.memcpy_htod(kernel_gpu, kernel)

    start_gpu = time.time()

    convolucionGPU(
        input_gpu,
        output_gpu_mem,
        kernel_gpu,
        np.int32(width),
        np.int32(height),
        np.int32(channels),
        np.int32(kSize),
        block=block,
        grid=grid
    )

    cuda.Context.synchronize()
    end_gpu = time.time()
    gpu_time = (end_gpu - start_gpu) * 1000
    print(f"GPU: {gpu_time:.2f} ms")

    # =====================================================
    # METRICAS DE RENDIMIENTO
    # =====================================================
    speedup = cpu_time / gpu_time
    eficiencia = speedup / 1024

    print(f"Aceleracion (Speedup): {speedup:.2f}")
    print(f"Eficiencia: {eficiencia:.6f}")

    # =====================================================
    # COPIAR RESULTADO GPU Y GUARDAR IMÁGENES
    # =====================================================
    cuda.memcpy_dtoh(output_gpu, output_gpu_mem)

    Image.fromarray(output_cpu).save(f"output_cpu_{kSize}x{kSize}.jpg")
    Image.fromarray(output_gpu).save(f"output_gpu_{kSize}x{kSize}.jpg")

    print(f"Imagen CPU guardada: output_cpu_{kSize}x{kSize}.jpg")
    print(f"Imagen GPU guardada: output_gpu_{kSize}x{kSize}.jpg")

    # Liberar memoria
    output_gpu_mem.free()
    kernel_gpu.free()

print("\nProcesamiento terminado con éxito")