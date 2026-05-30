from flask import Flask, request, jsonify, send_file
import cupy as cp
import cv2
import numpy as np
import os
import time
import traceback

app = Flask(__name__)

# ==============================================================================
# CAPA DE ABSORCIÓN DE ENTORNO DOCKER (.env)
# ==============================================================================
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")

UPLOAD_FOLDER = "processed_images"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# CATALOGO MAESTRO OFICIAL - 8 FILTROS EN TOTAL
MASCARAS_MASTER = {
    "CONVOLUCION_MANUAL": ["15x15", "150x150", "350x350"],
    "HIGH_BOOST": ["25x25", "71x71", "141x141"],
    "EMBOSS": ["5x5", "21x21", "45x45"],       
    "SHARPNESS": ["3x3", "15x15", "31x31"],    
    "GRAYSCALE_GPU": ["Matriz Fija GPU"],
    "PIXELADO": ["Bloque 8px", "Bloque 16px", "Bloque 32px"],
    "IDENTITY_UPS": ["Duotono Fijo"],
    "CR7_FRAME": ["Marco Canvas Remap"]
}

# ==============================================================================
# KERNELS CUDA EN CUPY (Paralelizacion en Hardware)
# ==============================================================================

# 1. Kernel para Filtros Dinamicos en Blanco y Negro (1 Canal)
kernelBW = cp.RawKernel(r'''
extern "C" __global__ 
void kernelBW(const unsigned char* in, unsigned char* out, int w, int h, int mask_size, int is_high_boost) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int offset = mask_size / 2;

    if (x < w && y < h) {
        float sum = 0.0f;
        float normalization = 1.0f / (float)(mask_size * mask_size);

        for (int ky = -offset; ky <= offset; ky++) {
            for (int kx = -offset; kx <= offset; kx++) {
                int py = max(0, min(y + ky, h - 1));
                int px = max(0, min(x + kx, w - 1));
                float val = (float)in[py * w + px];

                if (is_high_boost == 1) {
                    if (ky == 0 && kx == 0) {
                        sum += val * 2.0f; 
                    } else {
                        sum += val * (-1.0f * normalization);
                    }
                } else {
                    sum += val * normalization;
                }
            }
        }
        out[y * w + x] = (unsigned char)max(0.0f, min(sum, 255.0f));
    }
}
''', 'kernelBW')

# 2. Kernel Color Adaptativo (Nitidez Laplaciana y Relieve Emboss)
kernelColor = cp.RawKernel(r'''
extern "C" __global__ 
void kernelColor(const unsigned char* input, unsigned char* output, int width, int height, int channels, int kSize, int is_sharpness) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        for(int c = 0; c < channels; c++) {
            int idx = (y * width + x) * channels + c;
            float pixel_central = (float)input[idx];

            if (is_sharpness == 1) {
                int top_y    = max(0, y - 1);
                int bottom_y = min(height - 1, y + 1);
                int left_x   = max(0, x - 1);
                int right_x  = min(width - 1, x + 1);

                float n_top    = (float)input[(top_y * width + x) * channels + c];
                float n_bottom = (float)input[(bottom_y * width + x) * channels + c];
                float n_left   = (float)input[(y * width + left_x) * channels + c];
                float n_right  = (float)input[(y * width + right_x) * channels + c];

                float factor_potencia = (kSize > 15) ? 3.5f : 1.8f;

                float laplaciano = (4.0f * pixel_central) - (n_top + n_bottom + n_left + n_right);
                float resultado = pixel_central + (laplaciano * factor_potencia);

                output[idx] = (unsigned char)max(0.0f, min(resultado, 255.0f));
            } 
            else {
                float suma = 0.0f;
                int offset = kSize / 2;
                for(int ky = -offset; ky <= offset; ky++) {
                    for(int kx = -offset; kx <= offset; kx++) {
                        int px = max(0, min(x + kx, width - 1));
                        int py = max(0, min(y + ky, height - 1));
                        float val = (float)input[(py * width + px) * channels + c];

                        if (ky == -offset && kx == -offset) suma += val * -2.0f;
                        else if (ky == offset && kx == offset) suma += val * 2.0f;
                        else if (ky == 0 && kx == 0) suma += val * 1.0f;
                    }
                }
                output[idx] = (unsigned char)max(0.0f, min(suma, 255.0f));
            }
        }
    }
}
''', 'kernelColor')

# 3. KERNEL PREMIUM IDENTIDAD UPS
kernelUPSPremium = cp.RawKernel(r'''
extern "C" __global__ 
void kernelUPSPremium(const unsigned char* in, unsigned char* out, const unsigned char* logo, const unsigned char* db, 
                      int w, int h, int channels, int logo_w, int logo_h, int db_w, int db_h) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int idx = (y * w + x) * channels;
        
        int marco_externo = max(6, w / 120);
        int marco_interno = marco_externo + max(6, w / 150);
        
        if (x < marco_externo || x > (w - marco_externo) || y < marco_externo || y > (h - marco_externo)) {
            out[idx] = 0; out[idx+1] = 215; out[idx+2] = 255;
            return;
        }
        if (x < marco_interno || x > (w - marco_interno) || y < marco_interno || y > (h - marco_interno)) {
            out[idx] = 138; out[idx+1] = 58; out[idx+2] = 30;
            return;
        }

        int start_logo_x = w - logo_w - marco_interno - 15;
        int start_logo_y = marco_interno + 15;                
        int start_db_x = marco_interno + 15;                   
        int start_db_y = h - db_h - marco_interno - 15;

        if (x >= start_logo_x && x < start_logo_x + logo_w && y >= start_logo_y && y < start_logo_y + logo_h) {
            int lx = x - start_logo_x; int ly = y - start_logo_y;
            int l_idx = (ly * logo_w + lx) * channels;
            
            if (logo[l_idx] < 230 || logo[l_idx+1] < 230 || logo[l_idx+2] < 230) {
                out[idx] = logo[l_idx]; out[idx+1] = logo[l_idx+1]; out[idx+2] = logo[l_idx+2];
                return;
            }
        }

        if (x >= start_db_x && x < start_db_x + db_w && y >= start_db_y && y < start_db_y + db_h) {
            int dbx = x - start_db_x; int dby = y - start_db_y;
            int db_idx = (dby * db_w + dbx) * channels;
            
            if (db[db_idx] > 15 || db[db_idx+1] > 15 || db[db_idx+2] > 15) {
                out[idx] = db[db_idx]; out[idx+1] = db[db_idx+1]; out[idx+2] = db[db_idx+2];
                return;
            }
        }

        int b = in[idx]; int g = in[idx+1]; int r = in[idx+2];
        int lum = (int)(0.299f * r + 0.587f * g + 0.114f * b);

        if (lum > 128) {
            out[idx] = 0; out[idx+1] = 215; out[idx+2] = 255;   
        } else {
            out[idx] = 138; out[idx+1] = 58; out[idx+2] = 30;    
        }
    }
}
''', 'kernelUPSPremium')

# 4. Kernel Pixelado Dinamico a Color (Efecto Censura / 8-Bits)
pixelado_kernel = cp.RawKernel(r'''
extern "C" __global__ 
void kernelPixelado(const unsigned char* in, unsigned char* out, int w, int h, int channels, int bSize) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int ax = (x / bSize) * bSize;
        int ay = (y / bSize) * bSize;
        int idx = (y * w + x) * channels;
        int aidx = (ay * w + ax) * channels;
        for(int c=0; c<channels; c++) out[idx+c] = in[aidx+c];
    }
}
''', 'kernelPixelado')

# 5. KERNEL: Inversion de Contraste por Mitad Espacial
kernelMitadContraste = cp.RawKernel(r'''
extern "C" __global__ 
void kernelMitadContraste(const unsigned char* in, unsigned char* out, int w, int h, int channels) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int idx = (y * w + x) * channels;

        float b = (float)in[idx];
        float g = (float)in[idx+1];
        float r = (float)in[idx+2];

        int lum = (int)(0.299f * r + 0.587f * g + 0.114f * b);
        
        if (x < (w / 2)) {
            unsigned char val = (lum > 128) ? 255 : 0;
            for(int c = 0; c < channels; c++) out[idx + c] = val;
        } 
        else {
            unsigned char val = (lum > 128) ? 0 : 255;
            for(int c = 0; c < channels; c++) out[idx + c] = val;
        }
    }
}
''', 'kernelMitadContraste')

# 6. Kernel Maestro CR7
kernelCR7 = cp.RawKernel(r'''
extern "C" __global__ 
void kernelCR7Master(const unsigned char* user_img, const unsigned char* collage, unsigned char* out, 
                     int w, int h, int channels, int start_x, int end_x, int start_y, int end_y) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h) {
        int idx = (y * w + x) * channels;

        if (x >= start_x && x < end_x && y >= start_y && y < end_y) {
            int user_x = (int)(((float)(x - start_x) / (float)(end_x - start_x)) * w);
            int user_y = (int)(((float)(y - start_y) / (float)(end_y - start_y)) * h);
            
            if (user_x < 0) user_x = 0; if (user_x >= w) user_x = w - 1;
            if (user_y < 0) user_y = 0; if (user_y >= h) user_y = h - 1;
            
            int user_idx = (user_y * w + user_x) * channels;

            for (int c = 0; c < channels; c++) {
                out[idx + c] = user_img[user_idx + c];
            }
        } 
        else {
            for (int c = 0; c < channels; c++) {
                out[idx + c] = collage[idx + c];
            }
        }
    }
}
''', 'kernelCR7Master')

# ==============================================================================
# ENDPOINTS DE LA API REST HIBRIDA
# ==============================================================================

@app.route('/api/pycuda/apply-filter', methods=['POST'])
def apply_filter():
    try:
        if 'image' not in request.files:
            return jsonify({"status": "FAILED", "error": "Falta el archivo de imagen"}), 400

        file = request.files['image']
        filtro = request.form.get('filter', 'CONVOLUCION_MANUAL')
        
        file_bytes = np.frombuffer(file.read(), np.uint8)
        img_temp = cv2.imdecode(file_bytes, cv2.IMREAD_UNCHANGED)
        h, w = img_temp.shape[0], img_temp.shape[1]
        total_pixeles = w * h
        
        mask_size = 3
        if filtro == "CONVOLUCION_MANUAL":
            if total_pixeles > 2000000:   mask_size = 350
            elif total_pixeles > 800000:  mask_size = 150
            else:                         mask_size = 15
        elif filtro == "HIGH_BOOST":
            if total_pixeles > 2000000:   mask_size = 141
            elif total_pixeles > 800000:  mask_size = 71
            else:                         mask_size = 25
        elif filtro == "EMBOSS": 
            if total_pixeles > 2000000:   mask_size = 45  
            elif total_pixeles > 800000:  mask_size = 21  
            else:                         mask_size = 5   
        elif filtro == "SHARPNESS": 
            if total_pixeles > 2000000:   mask_size = 31  
            elif total_pixeles > 800000:  mask_size = 15  
            else:                         mask_size = 3   
        elif filtro == "PIXELADO": 
            if total_pixeles > 2000000:   mask_size = 32  
            elif total_pixeles > 800000:  mask_size = 16
            else:                         mask_size = 8

        print(f"Computo Automatico CUDA: [{filtro}] | Resolucion: {w}x{h}", flush=True)

        # Dimensiones tridimensionales explicitas para hilos y bloques de hardware
        block_dim = (16, 16, 1)
        grid_x = int((w + 15) / 16)
        grid_y = int((h + 15) / 16)
        grid_dim = (grid_x, grid_y, 1)
        
        start_time = time.time()
        
        if filtro in ["CONVOLUCION_MANUAL", "HIGH_BOOST"]:
            img = cv2.imdecode(file_bytes, cv2.IMREAD_GRAYSCALE)
            img_gpu = cp.array(img, dtype=cp.uint8)
            res_gpu = cp.empty_like(img_gpu)
            
            is_high_boost = 1 if filtro == "HIGH_BOOST" else 0
            
            kernelBW(grid_dim, block_dim, (img_gpu, res_gpu, w, h, mask_size, is_high_boost))
            cp.cuda.Stream.null.synchronize()
            res_cpu_final = res_gpu.get()
            
        else:
            img = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
            if img.shape[2] == 4:
                img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
            c = img.shape[2]
            
            img_gpu = cp.array(img, dtype=cp.uint8)
            res_gpu = cp.empty_like(img_gpu)
            
            if filtro == "IDENTITY_UPS":
                logo_np = cv2.imread("logo_ups.png", cv2.IMREAD_COLOR)
                db_np = cv2.imread("don_bosco.png", cv2.IMREAD_COLOR)
                
                if logo_np is None: logo_np = np.zeros((100, 100, 3), dtype=np.uint8)
                if db_np is None: db_np = np.zeros((100, 100, 3), dtype=np.uint8)
                
                logo_h_orig, logo_w_orig = logo_np.shape[0], logo_np.shape[1]
                lw = int(w * 0.22)  
                scale_factor = lw / logo_w_orig
                lh = int(logo_h_orig * scale_factor)
                if lh <= 0: lh = 1
                
                db_h_orig, db_w_orig = db_np.shape[0], db_np.shape[1]
                dbw = int(w * 0.45) 
                db_scale = dbw / db_w_orig
                dbh = int(db_h_orig * db_scale)
                if dbh <= 0: dbh = 1
                
                logo_res = cv2.resize(logo_np, (lw, lh), interpolation=cv2.INTER_AREA)
                db_res = cv2.resize(db_np, (dbw, dbh), interpolation=cv2.INTER_AREA)
                
                logo_gpu = cp.array(logo_res, dtype=cp.uint8)
                db_gpu = cp.array(db_res, dtype=cp.uint8)
                
                kernelUPSPremium(grid_dim, block_dim, (img_gpu, res_gpu, logo_gpu, db_gpu, w, h, c, lw, lh, dbw, dbh))
                
            elif filtro == "PIXELADO":
                pixelado_kernel(grid_dim, block_dim, (img_gpu, res_gpu, w, h, c, mask_size))
                
            elif filtro == "GRAYSCALE_GPU":
                kernelMitadContraste(grid_dim, block_dim, (img_gpu, res_gpu, w, h, c))
                
            elif filtro == "CR7_FRAME":
                collage_np = cv2.imread("collage_cr7.jpg", cv2.IMREAD_COLOR)
                if collage_np is None:
                    collage_np = np.zeros((h, w, 3), dtype=np.uint8)
                
                collage_res = cv2.resize(collage_np, (w, h), interpolation=cv2.INTER_AREA)
                collage_gpu = cp.array(collage_res, dtype=cp.uint8)
                
                start_x = int(w * 0.19)
                end_x   = int(w * 0.81)
                start_y = int(h * 0.19)
                end_y   = int(h * 0.80)
                
                kernelCR7(grid_dim, block_dim, (img_gpu, collage_gpu, res_gpu, w, h, c, start_x, end_x, start_y, end_y))
                
            else:
                is_sharpness = 1 if filtro == "SHARPNESS" else 0
                kernelColor(grid_dim, block_dim, (img_gpu, res_gpu, w, h, c, mask_size, is_sharpness))
            
            cp.cuda.Stream.null.synchronize()
            res_cpu_final = res_gpu.get()

        kernel_time_ms = (time.time() - start_time) * 1000.0

        output_filename = f"proc_{int(time.time())}.jpg"
        output_path = os.path.join(UPLOAD_FOLDER, output_filename)
        cv2.imwrite(output_path, res_cpu_final)

        if filtro == "CR7_FRAME":
            applied_mask_str = "45x45"  
        else:
            applied_mask_str = f"{mask_size}x{mask_size}"
            
        return jsonify({
            "status": "COMPLETED",
            "processedPath": output_path,
            "imageWidth": w, "imageHeight": h,
            "kernelTimeMs": round(kernel_time_ms, 4),
            "appliedMask": applied_mask_str,
            "gridDimX": grid_dim[0],
            "gridDimY": grid_dim[1]
        }), 200

    except Exception as e:
        print(f"🚨 ERROR CRÍTICO EN KERNEL CUDA: {str(e)}", flush=True)
        traceback.print_exc()
        return jsonify({"status": "FAILED", "error": str(e)}), 500

@app.route('/api/pycuda/download', methods=['GET'])
def download_file():
    path = request.args.get('path')
    if path and os.path.exists(path):
        return send_file(path, mimetype="image/jpeg")
    return jsonify({"error": "No encontrado"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)