#include <opencv2/opencv.hpp>
#include <iostream>
#include <chrono>
#include <algorithm>
#include "filtros.h"

using namespace cv;
using namespace std;

void convolutionCPU(const Mat& in, Mat& out, float* mask) {
    int offset = MASK_SIZE / 2;
    int rows = in.rows;
    int cols = in.cols;
    const uchar* inputPtr = in.data;
    uchar* outputPtr = out.data;

    // Factor de normalización (1/65536 para 256x256)
    double normFactor = (double)mask[0]; 

    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
            double pixelSum = 0.0; 

            for (int ky = -offset; ky <= offset; ky++) {
                for (int kx = -offset; kx <= offset; kx++) {
                    int py = std::min(std::max(y + ky, 0), rows - 1);
                    int px = std::min(std::max(x + kx, 0), cols - 1);
                    pixelSum += (double)inputPtr[py * cols + px];
                }
            }
            
            double finalValue = pixelSum * normFactor;

            // Clamping para asegurar el rango 0-255
            if (finalValue > 255.0) finalValue = 255.0;
            if (finalValue < 0.0) finalValue = 0.0;

            outputPtr[y * cols + x] = (uchar)finalValue;
        }
    }
}

int main() {
    Mat img = imread("WhatsApp Image 2026-05-04 at 16.40.15-6000x6000.jpg.jpeg", IMREAD_GRAYSCALE);
    if (img.empty()) return -1;

    Mat res = Mat::zeros(img.size(), CV_8UC1);
    float* h_mask = new float[MASK_SIZE * MASK_SIZE];
    generarFiltro(h_mask);

    cout << "Calculando Secuencial (Kernel 150x150)..." << endl;
    auto start = chrono::high_resolution_clock::now();
    convolutionCPU(img, res, h_mask);
    auto end = chrono::high_resolution_clock::now();

    cout << "TIEMPO_CPU (Ts): " << chrono::duration<double>(end - start).count() << " s" << endl;
    imwrite("resultado_secuencial.jpg", res);

    delete[] h_mask;
    return 0;
}