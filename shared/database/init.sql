-- shared/database/init.sql
-- Inicialización automática de esquemas para October CMS multi-versión

-- =============================================
-- CONFIGURACIÓN INICIAL BASE DE DATOS
-- =============================================

-- Crear esquemas para cada versión de October
CREATE SCHEMA IF NOT EXISTS october_v3;
CREATE SCHEMA IF NOT EXISTS october_v4;

-- Configurar permisos para el usuario de October
GRANT ALL PRIVILEGES ON SCHEMA october_v3 TO october_user;
GRANT ALL PRIVILEGES ON SCHEMA october_v4 TO october_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA october_v3 TO october_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA october_v4 TO october_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA october_v3 TO october_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA october_v4 TO october_user;

-- Permisos por defecto para objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA october_v3 GRANT ALL ON TABLES TO october_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA october_v4 GRANT ALL ON TABLES TO october_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA october_v3 GRANT ALL ON SEQUENCES TO october_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA october_v4 GRANT ALL ON SEQUENCES TO october_user;

-- =============================================
-- EXTENSIONES POSTGRESQL REQUERIDAS
-- =============================================

-- Extensión para UUID (requerida por Laravel)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extensión para funciones de texto avanzadas
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- Extensión para búsqueda de texto completo
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================
-- CONFIGURACIÓN ESPECÍFICA OCTOBER CMS
-- =============================================

-- Establecer search_path por defecto para october_user
ALTER USER october_user SET search_path = october_v3, october_v4, public;

-- =============================================
-- TABLAS DE CONTROL PARA INSTALACIÓN
-- =============================================

-- Tabla para rastrear el estado de instalación de cada versión
CREATE TABLE IF NOT EXISTS public.october_installation_status (
    version VARCHAR(10) PRIMARY KEY,
    schema_name VARCHAR(50) NOT NULL,
    installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Insertar registros iniciales
INSERT INTO public.october_installation_status (version, schema_name, status, notes) 
VALUES 
    ('3.7', 'october_v3', 'schema_ready', 'Schema created, pending October installation'),
    ('4.0', 'october_v4', 'schema_ready', 'Schema created, pending October installation')
ON CONFLICT (version) DO NOTHING;

-- =============================================
-- FUNCIONES AUXILIARES
-- =============================================

-- Función para actualizar el estado de instalación
CREATE OR REPLACE FUNCTION update_installation_status(
    p_version VARCHAR(10),
    p_status VARCHAR(20),
    p_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.october_installation_status 
    SET 
        status = p_status,
        last_updated = CURRENT_TIMESTAMP,
        notes = COALESCE(p_notes, notes)
    WHERE version = p_version;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar si una versión está instalada
CREATE OR REPLACE FUNCTION is_october_installed(p_version VARCHAR(10))
RETURNS BOOLEAN AS $$
DECLARE
    table_count INTEGER;
    schema_name VARCHAR(50);
BEGIN
    -- Obtener el nombre del schema
    SELECT s.schema_name INTO schema_name 
    FROM public.october_installation_status s 
    WHERE s.version = p_version;
    
    IF schema_name IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Contar tablas en el schema (October debería tener al menos 10 tablas base)
    EXECUTE format('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = %L', schema_name)
    INTO table_count;
    
    RETURN table_count >= 10;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TRIGGERS PARA MONITOREO
-- =============================================

-- Trigger para actualizar timestamp cuando cambia el status
CREATE OR REPLACE FUNCTION update_installation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_installation_status_update ON public.october_installation_status;
CREATE TRIGGER tr_installation_status_update
    BEFORE UPDATE ON public.october_installation_status
    FOR EACH ROW
    EXECUTE FUNCTION update_installation_timestamp();

-- =============================================
-- CONFIGURACIÓN DE LOGS
-- =============================================

-- Crear tabla para logs de instalación
CREATE TABLE IF NOT EXISTS public.october_installation_logs (
    id SERIAL PRIMARY KEY,
    version VARCHAR(10) NOT NULL,
    level VARCHAR(10) NOT NULL DEFAULT 'info',
    message TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Función para insertar logs
CREATE OR REPLACE FUNCTION log_installation(
    p_version VARCHAR(10),
    p_level VARCHAR(10),
    p_message TEXT,
    p_context JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.october_installation_logs (version, level, message, context)
    VALUES (p_version, p_level, p_message, p_context);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DATOS INICIALES
-- =============================================

-- Log inicial
SELECT log_installation('system', 'info', 'Database schemas initialized for October CMS multi-version', 
    '{"schemas": ["october_v3", "october_v4"], "extensions": ["uuid-ossp", "unaccent", "pg_trgm"]}'::jsonb);

-- =============================================
-- VERIFICACIÓN FINAL
-- =============================================

-- Mostrar estado actual
DO $$
BEGIN
    RAISE NOTICE '=== October CMS Multi-Version Database Initialization ===';
    RAISE NOTICE 'Schema october_v3: Ready for October CMS v3.7';
    RAISE NOTICE 'Schema october_v4: Ready for October CMS v4.0';
    RAISE NOTICE 'Extensions installed: uuid-ossp, unaccent, pg_trgm';
    RAISE NOTICE 'Monitoring tables: october_installation_status, october_installation_logs';
    RAISE NOTICE '===============================================';
END $$;