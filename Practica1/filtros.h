#ifndef FILTROS_H
#define FILTROS_H

// Definición de la máscara de 256x256
#define MASK_SIZE 150

void generarFiltro(float* mask) {
    // El área ahora es de 65,536 elementos
    double area = (double)MASK_SIZE * (double)MASK_SIZE;
    float valor = (float)(1.0 / area); 

    for (int i = 0; i < MASK_SIZE * MASK_SIZE; i++) {
        mask[i] = valor;
    }
}

#endif