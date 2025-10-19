-- =====================================
-- AUDIENCIA REPORTS - Novogrebelska Mezger
-- Archivo: audiencia_reports.sql
-- Contiene: Vistas analíticas, Funciones, Stored Procedures y Triggers
-- Requiere que el esquema `audiencia_diario` y las tablas relacionadas existan.
-- Ejecutar después de haber creado las tablas principales y de haber insertado datos.
-- =====================================

USE audiencia_diario;

-- -----------------------------
-- VISTAS ANALÍTICAS (5)
-- -----------------------------

-- 1) Audiencia por sección: visitas y tiempo promedio de lectura
CREATE OR REPLACE VIEW vista_audiencia_por_seccion AS
SELECT s.id_seccion,
       s.nombre AS seccion,
       COUNT(h.id_audiencia) AS visitas,
       ROUND(AVG(h.tiempo_lectura),2) AS tiempo_lectura_promedio
FROM hecho_audiencia h
JOIN articulos a ON h.id_articulo = a.id_articulo
JOIN secciones s ON a.id_seccion = s.id_seccion
GROUP BY s.id_seccion, s.nombre;

-- 2) Top 10 artículos por visitas (acumulado)
CREATE OR REPLACE VIEW vista_top_articulos AS
SELECT a.id_articulo, a.titulo, a.fecha_publicacion, s.nombre AS seccion,
       COUNT(h.id_audiencia) AS visitas_totales,
       ROUND(AVG(h.tiempo_lectura),2) AS tiempo_lectura_promedio
FROM articulos a
LEFT JOIN hecho_audiencia h ON a.id_articulo = h.id_articulo
LEFT JOIN secciones s ON a.id_seccion = s.id_seccion
GROUP BY a.id_articulo, a.titulo, a.fecha_publicacion, s.nombre
ORDER BY visitas_totales DESC
LIMIT 10;

-- 3) Impacto por anunciante: impresiones, clics y CTR (por anunciante)
CREATE OR REPLACE VIEW vista_impacto_anunciante AS
SELECT an.id_anunciante, an.nombre AS anunciante,
       SUM(mp.impresiones) AS impresiones_total,
       SUM(mp.clics) AS clics_total,
       CASE WHEN SUM(mp.impresiones) > 0
            THEN ROUND(100 * SUM(mp.clics) / SUM(mp.impresiones),2)
            ELSE 0 END AS CTR_porcentaje,
       SUM(mp.conversiones) AS conversiones_total
FROM metricas_publicitarias mp
JOIN campanias c ON mp.id_campania = c.id_campania
JOIN anunciantes an ON c.id_anunciante = an.id_anunciante
GROUP BY an.id_anunciante, an.nombre;

-- 4) Usuarios más activos (últimos 30 días)
CREATE OR REPLACE VIEW vista_usuarios_activos AS
SELECT l.id_lector, l.nombre, l.ciudad, COUNT(h.id_audiencia) AS visitas_30d,
       ROUND(AVG(h.tiempo_lectura),2) AS tiempo_lectura_promedio_30d
FROM lectores l
JOIN hecho_audiencia h ON l.id_lector = h.id_lector
WHERE h.fecha_visita >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY l.id_lector, l.nombre, l.ciudad
ORDER BY visitas_30d DESC;

-- 5) Audiencia diaria (totales por fecha)
CREATE OR REPLACE VIEW vista_audiencia_diaria AS
SELECT h.fecha_visita AS fecha,
       COUNT(h.id_audiencia) AS visitas_totales,
       ROUND(AVG(h.tiempo_lectura),2) AS tiempo_lectura_promedio
FROM hecho_audiencia h
GROUP BY h.fecha_visita
ORDER BY h.fecha_visita DESC;

-- -----------------------------
-- FUNCIONES (2)
-- -----------------------------

-- 1) Calcular CTR básico (porcentaje)
DELIMITER $$
CREATE FUNCTION calcular_ctr(impr INT, clics INT)
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
  IF impr IS NULL OR impr = 0 THEN
    RETURN 0.00;
  END IF;
  RETURN ROUND(100.0 * clics / impr, 2);
END $$
DELIMITER ;

-- 2) Lecturas totales por lector
DELIMITER $$
CREATE FUNCTION fn_lecturas_por_lector(p_id_lector INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT COUNT(*) INTO total FROM hecho_audiencia WHERE id_lector = p_id_lector;
  RETURN IFNULL(total, 0);
END $$
DELIMITER ;

-- -----------------------------
-- STORED PROCEDURES (2)
-- -----------------------------

-- 1) Top secciones por periodo (parámetros: fecha_inicio, fecha_fin)
DELIMITER $$
CREATE PROCEDURE sp_top_secciones_por_periodo(
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE,
  IN p_limit INT
)
BEGIN
  SELECT s.id_seccion, s.nombre AS seccion,
         COUNT(h.id_audiencia) AS visitas_periodo,
         ROUND(AVG(h.tiempo_lectura),2) AS tiempo_lectura_promedio
  FROM hecho_audiencia h
  JOIN articulos a ON h.id_articulo = a.id_articulo
  JOIN secciones s ON a.id_seccion = s.id_seccion
  WHERE h.fecha_visita BETWEEN p_fecha_inicio AND p_fecha_fin
  GROUP BY s.id_seccion, s.nombre
  ORDER BY visitas_periodo DESC
  LIMIT p_limit;
END $$
DELIMITER ;

-- 2) Resumen de una campaña (por id_campania)
DELIMITER $$
CREATE PROCEDURE sp_resumen_campania(IN p_id_campania INT)
BEGIN
  SELECT c.id_campania, an.nombre AS anunciante, c.fecha_inicio, c.fecha_fin,
         SUM(mp.impresiones) AS impresiones_total,
         SUM(mp.clics) AS clics_total,
         ROUND(CASE WHEN SUM(mp.impresiones)>0 THEN 100 * SUM(mp.clics)/SUM(mp.impresiones) ELSE 0 END,2) AS CTR_porcentaje,
         SUM(mp.conversiones) AS conversiones_total
  FROM campanias c
  JOIN anunciantes an ON c.id_anunciante = an.id_anunciante
  LEFT JOIN metricas_publicitarias mp ON c.id_campania = mp.id_campania
  WHERE c.id_campania = p_id_campania
  GROUP BY c.id_campania, an.nombre, c.fecha_inicio, c.fecha_fin;
END $$
DELIMITER ;

-- -----------------------------
-- TRIGGERS (2)
-- -----------------------------

-- 1) Normalizar tiempo_lectura y fecha_visita antes de insertar un registro de audiencia
DELIMITER $$
CREATE TRIGGER trg_hecho_audiencia_before_insert
BEFORE INSERT ON hecho_audiencia
FOR EACH ROW
BEGIN
  -- Evita tiempos negativos
  IF NEW.tiempo_lectura IS NULL OR NEW.tiempo_lectura < 0 THEN
    SET NEW.tiempo_lectura = 0;
  END IF;
  -- Si no se provee fecha_visita, asigna la fecha actual
  IF NEW.fecha_visita IS NULL THEN
    SET NEW.fecha_visita = CURDATE();
  END IF;
END $$
DELIMITER ;

-- 2) Normalizar tiempo_lectura antes de actualizar un registro de audiencia
DELIMITER $$
CREATE TRIGGER trg_hecho_audiencia_before_update
BEFORE UPDATE ON hecho_audiencia
FOR EACH ROW
BEGIN
  IF NEW.tiempo_lectura IS NULL OR NEW.tiempo_lectura < 0 THEN
    SET NEW.tiempo_lectura = 0;
  END IF;
END $$
DELIMITER ;

-- FIN archivo: audiencia_reports.sql
