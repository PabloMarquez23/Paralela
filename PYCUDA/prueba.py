import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule

import numpy

a = numpy.random.randint(5, size=10).astype(numpy.int32)
b = numpy.random.randint(5, size=10).astype(numpy.int32)
c = numpy.zeros_like(a)

a_gpu = cuda.mem_alloc(a.nbytes)
b_gpu = cuda.mem_alloc(b.nbytes)
c_gpu = cuda.mem_alloc(c.nbytes)

cuda.memcpy_htod(a_gpu, a)
cuda.memcpy_htod(b_gpu, b)
cuda.memcpy_htod(c_gpu, c)


mod = SourceModule("""
  __global__ void sum_arrays(int *a, int *b, int *c)
  {
    int idx = blockIdx.x;
    if(idx < 10){
      c[idx] = a[idx] + b[idx];
    }
  }
  """)

func = mod.get_function("sum_arrays")
func(cuda.In(a),cuda.In(b),cuda.Out(c), grid=(10,1), block=(1,1,1))



print ("ORIGINAL ARRAY")
print (a)
print (b)
print ("ARRAYS SUM AFTER PyCUDA EXECUTION")
print (c)