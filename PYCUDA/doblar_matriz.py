import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
import numpy

# 1. Crear una matriz aleatoria de 5x5
a = numpy.random.randn(5,5)
a = a.astype(numpy.float32)

# 2. Reservar memoria en la GPU y copiar los datos desde el Host (CPU)
a_gpu = cuda.mem_alloc(a.nbytes)
cuda.memcpy_htod(a_gpu, a)

# 3. Definir el Kernel (Código que se ejecuta en la GPU)
mod = SourceModule("""
    __global__ void doubles_matrix(float *a)
    {
        int idx = threadIdx.x + threadIdx.y*4;
        a[idx] *= 2;
    }
""")

# 4. Obtener la función del kernel y ejecutarla
func = mod.get_function("doubles_matrix")
func(a_gpu, block=(5,5,1))

# 5. Crear espacio para el resultado y copiar de vuelta al Host (CPU)
a_doubled = numpy.empty_like(a)
cuda.memcpy_dtoh(a_doubled, a_gpu)

# 6. Mostrar resultados
print("ORIGINAL MATRIX")
print(a)
print("DOUBLED MATRIX AFTER PyCUDA EXECUTION")
print(a_doubled)