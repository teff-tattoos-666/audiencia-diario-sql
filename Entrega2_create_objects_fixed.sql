-- =====================================
-- ENTREGA 2 - NOVOGREBELSKA MEZGER
-- Creación de Schema, Tabla, Vistas, Funciones,
-- Stored Procedures y Trigger
-- =====================================

-- Crear el schema y usarlo
CREATE DATABASE IF NOT EXISTS audiencia_diario;
USE audiencia_diario;

-- Crear la tabla principal
CREATE TABLE IF NOT EXISTS audiencia_diario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL,
    programa VARCHAR(100) NOT NULL,
    cantidad_oyentes INT NOT NULL
);

-- VISTAS
CREATE OR REPLACE VIEW vista_audiencia_promedio AS
SELECT programa, AVG(cantidad_oyentes) AS promedio_oyentes
FROM audiencia_diario
GROUP BY programa;

CREATE OR REPLACE VIEW vista_maxima_audiencia AS
SELECT fecha, programa, cantidad_oyentes
FROM audiencia_diario a
WHERE cantidad_oyentes = (
  SELECT MAX(cantidad_oyentes) FROM audiencia_diario WHERE fecha = a.fecha
);

CREATE OR REPLACE VIEW vista_audiencia_semanal AS
SELECT WEEK(fecha) AS semana, programa, SUM(cantidad_oyentes) AS total_semanal
FROM audiencia_diario
GROUP BY WEEK(fecha), programa;

-- FUNCIONES
DELIMITER //
CREATE FUNCTION obtener_audiencia_total(fecha_consulta DATE)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT SUM(cantidad_oyentes) INTO total
  FROM audiencia_diario
  WHERE fecha = fecha_consulta;
  RETURN IFNULL(total,0);
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION promedio_programa(nombre_prog VARCHAR(100))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE promedio DECIMAL(10,2);
  SELECT AVG(cantidad_oyentes) INTO promedio
  FROM audiencia_diario
  WHERE programa = nombre_prog;
  RETURN IFNULL(promedio,0);
END //
DELIMITER ;

-- STORED PROCEDURES
DELIMITER //
CREATE PROCEDURE top_programa(IN fecha_consulta DATE)
BEGIN
  SELECT programa, cantidad_oyentes
  FROM audiencia_diario
  WHERE fecha = fecha_consulta
  ORDER BY cantidad_oyentes DESC
  LIMIT 1;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE ranking_programas(IN semana INT)
BEGIN
  SELECT programa, SUM(cantidad_oyentes) AS total_oyentes
  FROM audiencia_diario
  WHERE WEEK(fecha) = semana
  GROUP BY programa
  ORDER BY total_oyentes DESC;
END //
DELIMITER ;

-- TRIGGER
DELIMITER //
CREATE TRIGGER trg_validar_oyentes
BEFORE INSERT ON audiencia_diario
FOR EACH ROW
BEGIN
  IF NEW.cantidad_oyentes < 0 THEN
    SET NEW.cantidad_oyentes = 0;
  END IF;
END //
DELIMITER ;
