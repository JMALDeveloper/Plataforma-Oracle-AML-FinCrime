-- =============================================================================
-- AUTOR: JOAQUÍN MANUEL ALPAÑEZ LÓPEZ
-- SCRIPT: 01_base_security.sql
-- DESCRIPCIÓN: CONFIGURACIÓN BASE DE SEGURIDAD – ENTORNO BANCARIO / FINCRIME
-- ORACLE DATABASE: Oracle 12c XE (compatible 12c+)
-- EJECUCIÓN: SYS / SYSDBA
-- CONTENEDOR OBJETIVO: XEPDB1
-- ENTORNO: DESARROLLO / PRUEBAS (Diseño extrapolable a PRODUCCIÓN)
-- =============================================================================

-- =============================================================================
-- CONTEXTO FUNCIONAL:
--   Configuración base de seguridad para una plataforma AML / FinCrime
--   orientada a banca Tier-1.
--
-- ALCANCE:
--   - Tablespaces base (NO específicos Big Data)
--   - Auditoría general
--   - Perfiles de seguridad
--   - Roles transversales
--
-- FUERA DE ALCANCE:
--   - Tablespaces especializados RT / Batch / BI
--   - Esquemas funcionales AML
--   - Objetos de negocio
--
-- NOTA ARQUITECTÓNICA:
--   La separación por patrón de carga (RealTime / Batch / Staging)
--   se implementa en scripts posteriores.
-- =============================================================================

-- =============================================================================
-- 1. CONFIGURACIÓN DE CONTENEDOR Y AUDITORÍA GLOBAL
-- =============================================================================

ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Activación de auditoría clásica (compatible entornos legacy AML)
-- NOTA: Requiere reinicio de la instancia
ALTER SYSTEM SET AUDIT_TRAIL = DB, EXTENDED SCOPE = SPFILE;
-- En entornos Big Data y Oracle 12c+ se recomienda
-- Unified Auditing con políticas específicas
-- para reducir impacto y mejorar reporting.

ALTER PLUGGABLE DATABASE XEPDB1 OPEN;
ALTER PLUGGABLE DATABASE XEPDB1 SAVE STATE;

ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE;
-- Uso exclusivo en Oracle XE / entornos locales
-- NO permitido en producción de nivel 1

-- NOTA PROFESIONAL:
-- En entornos modernos se recomienda UNIFIED AUDITING.
-- Este script mantiene auditoría clásica por compatibilidad
-- con plataformas AML legacy (NetReveal / Norkom).

-- =============================================================================
-- 2. CONFIGURACIÓN DE TABLESPACES BASE
-- =============================================================================

-- =============================================================================
-- TABLESPACES BASE
--
-- Estos tablespaces proporcionan una base común de almacenamiento
-- para entornos de desarrollo y pruebas.
--
-- En entornos Tier-1 con Big Data AML:
--   - Se crearán tablespaces específicos por patrón de carga:
--     * RealTime (OLTP / Kafka / APIs)
--     * Batch (escenarios masivos AML)
--     * Staging (integraciones)
--     * BI / Reporting
--   - Dichos tablespaces se definen en scripts posteriores.
-- =============================================================================

------------------------------------------------
-- TABLESPACE DE DATOS
------------------------------------------------
CREATE TABLESPACE AML_DATA_TBS
DATAFILE 'AML_DATA_TBS01.DBF' SIZE 200M
AUTOEXTEND ON NEXT 20M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

------------------------------------------------
-- TABLESPACE DE ÍNDICES
------------------------------------------------
CREATE TABLESPACE AML_INDEX_TBS
DATAFILE 'AML_INDEX_TBS01.DBF' SIZE 200M
AUTOEXTEND ON NEXT 20M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- NOTAS:
-- Separación DATA / INDEX obligatoria en banca Tier-1.
-- AUTOEXTEND ON solo para DEV/TEST.
-- En PRODUCCIÓN: AUTOEXTEND OFF + control del volumen siguiente por DBA.

-- AUTOALLOCATE se utiliza aquí por simplicidad y flexibilidad.
-- En tablespaces Batch AML de alto volumen se recomienda
-- EXTENT MANAGEMENT UNIFORM para optimizar full scans.

-- =============================================================================
-- 3. PERFILES DE SEGURIDAD Y CONTRASEÑAS
-- =============================================================================

-- Perfil estándar bancario (base)
CREATE PROFILE AML_PROFILE_SECURE LIMIT
  FAILED_LOGIN_ATTEMPTS 5
  PASSWORD_LIFE_TIME 90
  PASSWORD_GRACE_TIME 5
  PASSWORD_REUSE_TIME 365
  PASSWORD_REUSE_MAX 5
  PASSWORD_VERIFY_FUNCTION ORA12C_VERIFY_FUNCTION;

-- NOTA:
-- En producción se definen perfiles distintos:
-- - APP
-- - REPORTING
-- - AUDITORÍA
-- - ADMINISTRACIÓN

-- Como añadido: En entornos productivos las credenciales
-- técnicas suelen gestionarse vía vault
-- (CyberArk, HashiCorp, etc.).

-- =============================================================================
-- 4. ROLES BASE (NO FUNCIONALES AML)
-- =============================================================================

------------------------------------------------
-- ROL: ADMINISTRADOR LIMITADO
------------------------------------------------
CREATE ROLE ROLE_ADMIN_LIMITED;

GRANT
  CREATE TABLE,
  CREATE VIEW,
  CREATE SEQUENCE,
  CREATE PROCEDURE,
  CREATE TRIGGER,
  CREATE SYNONYM
TO ROLE_ADMIN_LIMITED;

------------------------------------------------
-- ROL: APLICACIÓN BASE (RW controlado)
------------------------------------------------
CREATE ROLE ROLE_APP_BASE_RW;

GRANT
  CREATE SESSION
TO ROLE_APP_BASE_RW;

------------------------------------------------
-- ROL: AUDITORÍA (SOLO LECTURA)
------------------------------------------------
CREATE ROLE ROLE_AUDITOR_RO;

GRANT
  CREATE SESSION
TO ROLE_AUDITOR_RO;

------------------------------------------------
-- ROL: REPORTING / BI (SOLO LECTURA)
------------------------------------------------
CREATE ROLE ROLE_REPORTING_RO;

GRANT
  CREATE SESSION
TO ROLE_REPORTING_RO;

-- NOTA:
-- No se conceden privilegios ANY.
-- Los GRANT sobre objetos se harán
-- a nivel de esquema funcional (RT / BT).

-- =============================================================================
-- 5. AUDITORÍA BÁSICA (CUMPLIMIENTO REGULATORIO)
-- =============================================================================

-- Auditoría de sesiones
AUDIT CREATE SESSION BY ACCESS;

-- Auditoría de DDL sensible
AUDIT CREATE TABLE BY ACCESS;
AUDIT DROP ANY TABLE BY ACCESS;
AUDIT ALTER USER BY ACCESS;
AUDIT GRANT ANY PRIVILEGE BY ACCESS;

-- NOTA:
-- El nivel de auditoría se ampliará
-- en scripts posteriores por esquema AML.

-- =============================================================================
-- 6. VERIFICACIONES POSTERIORES
-- =============================================================================

-- Tablespaces
SELECT TABLESPACE_NAME, STATUS, CONTENTS
FROM DBA_TABLESPACES
WHERE TABLESPACE_NAME LIKE 'AML_%';

-- Roles
SELECT ROLE FROM DBA_ROLES WHERE ROLE LIKE 'ROLE_%';

-- Auditoría
SELECT USERNAME, ACTION_NAME, RETURNCODE
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'LOGON';

-- Perfiles
SELECT PROFILE, RESOURCE_NAME, LIMIT
FROM DBA_PROFILES
WHERE PROFILE = 'AML_PROFILE_SECURE';

-- El paralelismo de objetos se gestionará
-- a nivel de tabla / índice en scripts posteriores
-- según patrón de carga (RT vs Batch).

-- =============================================================================
-- FIN DEL SCRIPT
-- =============================================================================