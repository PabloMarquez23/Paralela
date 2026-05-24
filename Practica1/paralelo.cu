#include <opencv2/opencv.hpp>
#include <cuda_runtime.h>
#include <iostream>
#include "filtros.h"

using namespace cv;
using namespace std;

__global__ void kernelConvolucion(unsigned char* in, unsigned char* out, float* mask, int w, int h) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int offset = MASK_SIZE / 2;
        float sum = 0.0f;
        for (int ky = -offset; ky <= offset; ky++) {
            for (int kx = -offset; kx <= offset; kx++) {
                int py = min(max(y + ky, 0), h - 1);
                int px = min(max(x + kx, 0), w - 1);
                sum += (float)in[py * w + px] * mask[(ky + offset) * MASK_SIZE + (kx + offset)];
            }
        }
        out[y * w + x] = (unsigned char)fminf(fmaxf(sum, 0.0f), 255.0f);
    }
}

int main() {
    Mat img = imread("WhatsApp Image 2026-05-04 at 16.40.15-6000x6000.jpg.jpeg", IMREAD_GRAYSCALE);
    if (img.empty()) return -1;

    int w = img.cols, h = img.rows;
    float *h_mask = new float[MASK_SIZE * MASK_SIZE];
    generarFiltro(h_mask);

    unsigned char *d_in, *d_out;
    float *d_mask;
    cudaMalloc(&d_in, w * h);
    cudaMalloc(&d_out, w * h);
    cudaMalloc(&d_mask, MASK_SIZE * MASK_SIZE * sizeof(float));

    cudaMemcpy(d_in, img.data, w * h, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mask, h_mask, MASK_SIZE * MASK_SIZE * sizeof(float), cudaMemcpyHostToDevice);

    dim3 blockSize(16, 16);
    dim3 gridSize((w + 15) / 16, (h + 15) / 16);

    cudaEvent_t start, stop;
    cudaEventCreate(&start); cudaEventCreate(&stop);
    cudaEventRecord(start);

    kernelConvolucion<<<gridSize, blockSize>>>(d_in, d_out, d_mask, w, h);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    float Tp = ms / 1000.0f;
    cout << "TIEMPO_GPU (Tp) (Kernel 150x150): " << Tp << " s" << endl;

    Mat res(h, w, CV_8UC1);
    cudaMemcpy(res.data, d_out, w * h, cudaMemcpyDeviceToHost);
    imwrite("resultado_paralelo.jpg", res);

    return 0;
}