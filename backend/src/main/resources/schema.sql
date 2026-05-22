-- ==============================================================================
-- 🛠️ SCRIPT DE INICIALIZACIÓN DE BASE DE DATOS LOCAL (UPSGlam 3.0)
-- ==============================================================================

-- ==========================================
-- 1. EXTENSIONES Y SEGURIDAD INICIAL
-- ==========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 2. TABLA DE PERFILES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(), -- Ajustado para generación local autónoma
    username text UNIQUE NOT NULL,
    avatar_url text,
    bio text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- ==========================================
-- 3. TABLA DE FILTROS DISPONIBLES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.filters (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text,
    kernel_name text NOT NULL, -- Identificador para el microservicio PyCUDA
    is_active boolean DEFAULT true
);

-- ==========================================
-- 4. TABLA DE PUBLICACIONES (FEED SOCIAL)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    image_url text NOT NULL,       -- URL de Supabase Storage (Original)
    processed_url text,           -- URL de Supabase Storage (Con Filtro GPU)
    description text,
    created_at timestamp with time zone DEFAULT now()
);

-- ==========================================
-- 5. TABLA DE INTERACCIONES (LIKES Y COMENTARIOS)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.likes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(post_id, user_id) -- Evita que un usuario dé más de un like al mismo post
);

CREATE TABLE IF NOT EXISTS public.comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- ==========================================
-- 6. HISTORIAL DE PROCESAMIENTO Y MÉTRICAS GPU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.processing_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    filter_id uuid REFERENCES public.filters(id) ON DELETE SET NULL,
    
    original_image_url text NOT NULL,
    processed_image_url text,
    
    -- Dimensiones de la Imagen
    image_width integer NOT NULL,
    image_height integer NOT NULL,
    
    -- Métricas de Hardware (Esenciales para Computación Paralela)
    block_dim_x integer NOT NULL,
    block_dim_y integer NOT NULL,
    grid_dim_x integer NOT NULL,
    grid_dim_y integer NOT NULL,
    total_threads_launched bigint NOT NULL,
    
    -- Rendimiento
    kernel_time_ms numeric(10, 4) NOT NULL, -- Tiempo preciso devuelto por la GPU
    status text NOT NULL CHECK (status IN ('PROCESSING', 'COMPLETED', 'FAILED')),
    
    created_at timestamp with time zone DEFAULT now()
);

-- ==========================================
-- 7. PRECARGA DE FILTROS (INCLUYE IDENTIDAD UPS)
-- ==========================================
-- Usamos ON CONFLICT para evitar registros duplicados si el script se ejecuta más de una vez en Docker
INSERT INTO public.filters (name, description, kernel_name) VALUES
('Filtro Sobel (Bordes)', 'Detección de bordes verticales y horizontales mediante convolución.', 'sobel_kernel'),
('Desenfoque Gaussiano', 'Suavizado de imagen reduciendo el ruido de alta frecuencia.', 'gaussian_blur_kernel'),
('Filtro Sharpen', 'Resalta los detalles y el contraste de los bordes de la imagen.', 'sharpen_kernel'),
('Identidad UPS (Marca de Agua)', 'Aplica un blending paralelo superponiendo los colores institucionales y el logo UPS.', 'ups_identity_kernel')
ON CONFLICT DO NOTHING;