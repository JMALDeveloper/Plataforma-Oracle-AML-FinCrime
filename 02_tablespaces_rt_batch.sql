-- =============================================================================
-- AUTOR: JOAQUÍN MANUEL ALPAÑEZ LÓPEZ
-- SCRIPT: 02_tablespaces_rt_batch.sql
-- DESCRIPCIÓN: CREACIÓN Y OPTIMIZACIÓN DE TABLESPACES
--              POR PATRÓN DE CARGA (RT / BATCH / STAGING / BI)
-- ORACLE DATABASE: Oracle 12c+ (incluye XE para laboratorio)
-- EJECUCIÓN: SYS / SYSDBA
-- PDB OBJETIVO: XEPDB1
-- ENTORNO: DESARROLLO / PRUEBAS
--
-- PRECONDICIÓN:
--   El script 01_base_security.sql debe haberse ejecutado previamente.
--   Este script extiende la arquitectura de almacenamiento base
--   definida en AML_DATA_TBS / AML_INDEX_TBS.
-- =============================================================================

-- =============================================================================
-- CONTEXTO ARQUITECTÓNICO
--
-- En plataformas AML / FinCrime de banca Tier-1:
--   - No se utiliza un único tablespace
--   - Se separa el almacenamiento según el patrón de acceso:
--
--     * REALTIME  → OLTP, APIs, Kafka, baja latencia
--     * BATCH     → Escenarios AML masivos, full scans
--     * STAGING   → Integraciones, cargas intermedias
--     * REPORTING → BI, consultas analíticas
--
-- Este script simula dicha separación.
-- =============================================================================

ALTER SESSION SET CONTAINER = XEPDB1;

-- NOTA:
-- En despliegues reales se recomienda verificar
-- la existencia previa del tablespace antes de crear.

-- =============================================================================
-- 1. TABLESPACE REALTIME (OLTP / APIs / Kafka)
-- =============================================================================
-- Características:
--   - Acceso frecuente
--   - Baja latencia
--   - Alto volumen de INSERT / UPDATE
--   - Índices críticos

CREATE TABLESPACE AML_RT_DATA_TBS
DATAFILE 'AML_RT_DATA_TBS01.DBF' SIZE 300M
AUTOEXTEND ON NEXT 50M MAXSIZE 3G
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE AML_RT_INDEX_TBS
DATAFILE 'AML_RT_INDEX_TBS01.DBF' SIZE 200M
AUTOEXTEND ON NEXT 50M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- NOTA:
-- AUTOALLOCATE favorece cargas mixtas OLTP.
-- Adecuado para RealTime y baja latencia.

-- =============================================================================
-- 2. TABLESPACE BATCH (ESCENARIOS AML MASIVOS)
-- =============================================================================
-- Características:
--   - Full table scans
--   - Procesamiento nocturno
--   - Grandes volúmenes históricos
--   - Integración con Spark / Hadoop

CREATE TABLESPACE AML_BATCH_DATA_TBS
DATAFILE 'AML_BATCH_DATA_TBS01.DBF' SIZE 500M
AUTOEXTEND ON NEXT 100M MAXSIZE 5G
EXTENT MANAGEMENT LOCAL UNIFORM SIZE 8M
SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE AML_BATCH_INDEX_TBS
DATAFILE 'AML_BATCH_INDEX_TBS01.DBF' SIZE 300M
AUTOEXTEND ON NEXT 100M MAXSIZE 3G
EXTENT MANAGEMENT LOCAL UNIFORM SIZE 8M
SEGMENT SPACE MANAGEMENT AUTO;

-- NOTA PROFESIONAL:
-- UNIFORM reduce fragmentación y mejora
-- el rendimiento en scans masivos.
-- Patrón típico en AML Batch Tier-1.

-- =============================================================================
-- 3. TABLESPACE STAGING (INGESTA / INTEGRACIONES)
-- =============================================================================
-- Características:
--   - Datos temporales
--   - Truncados frecuentes
--   - Integraciones externas (ETL / APIs)

CREATE TABLESPACE AML_STG_DATA_TBS
DATAFILE 'AML_STG_DATA_TBS01.DBF' SIZE 300M
AUTOEXTEND ON NEXT 50M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- NOTA:
-- Staging prioriza flexibilidad sobre optimización fina.
-- En producción puede residir en storage diferenciado.

-- =============================================================================
-- 4. TABLESPACE REPORTING / BI
-- =============================================================================
-- Características:
--   - Consultas analíticas
--   - Acceso mayormente READ ONLY
--   - Integración con herramientas BI

CREATE TABLESPACE AML_BI_DATA_TBS
DATAFILE 'AML_BI_DATA_TBS01.DBF' SIZE 400M
AUTOEXTEND ON NEXT 100M MAXSIZE 4G
EXTENT MANAGEMENT LOCAL UNIFORM SIZE 16M
SEGMENT SPACE MANAGEMENT AUTO;

-- NOTA:
-- UNIFORM grande optimiza agregaciones
-- y lecturas secuenciales típicas de BI.

-- =============================================================================
-- 5. VERIFICACIONES POSTERIORES
-- =============================================================================

SELECT TABLESPACE_NAME,
       STATUS,
       EXTENT_MANAGEMENT,
       SEGMENT_SPACE_MANAGEMENT
FROM DBA_TABLESPACES
WHERE TABLESPACE_NAME LIKE 'AML_%'
ORDER BY TABLESPACE_NAME;

SELECT FILE_NAME, TABLESPACE_NAME, BYTES / 1024 / 1024 AS SIZE_MB
FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME LIKE 'AML_%'
ORDER BY TABLESPACE_NAME;

-- =============================================================================
-- NOTAS FINALES
--
-- * AUTOEXTEND habilitado SOLO para DEV / TEST.
-- * En PRODUCCIÓN:
--     - AUTOEXTEND OFF
--     - Gestión por DBAs
--     - Storage y ASM separados
--
-- * El paralelismo y compresión se definirán
--   a nivel de tabla / índice en ejercicios posteriores.
-- En entornos productivos Tier-1:
--   DATAFILES suelen gestionarse vía ASM
--   (ej. +DATA / +RECO)
--   Este script usa filesystem por simplicidad de laboratorio.

-- NOTA en referencia a BIG DATA:
--   Estos tablespaces NO pretenden sustituir motores Big Data.
--   Oracle actúa como:
--     - Sistema transaccional
--     - Persistencia AML
--     - Fuente de verdad regulatoria
--
--   Spark / Hadoop procesan,
--   Oracle gobierna y consolida.
-- =============================================================================

-- =============================================================================
-- FIN DEL SCRIPT
-- =============================================================================