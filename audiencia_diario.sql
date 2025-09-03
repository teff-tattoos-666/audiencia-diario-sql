-- ========================================================
-- Proyecto: Medición de Audiencia - Diario Digital
-- Script de creación de base de datos
-- Compatible con: MySQL 8.x
-- Autor: Estefania Novogrebelska Mezger
-- Fecha: 2025-09-01
-- ========================================================

-- 1) Crear base de datos
CREATE DATABASE IF NOT EXISTS audiencia_diario
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE audiencia_diario;

-- ========================================================
-- 2) Tablas maestras
-- ========================================================

-- Tabla: Categoria
CREATE TABLE categoria (
  id_categoria INT PRIMARY KEY AUTO_INCREMENT,
  nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255)
) ENGINE=InnoDB;

-- Tabla: Usuario
CREATE TABLE usuario (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  edad TINYINT UNSIGNED,
  genero ENUM('F','M','X','ND') NULL,
  ubicacion VARCHAR(120),
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla: Dispositivo
CREATE TABLE dispositivo (
  id_dispositivo INT PRIMARY KEY AUTO_INCREMENT,
  tipo ENUM('pc','movil','tablet','tv','otro') NOT NULL,
  sistema_operativo VARCHAR(80) NOT NULL,
  navegador VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

-- Tabla: Noticia
CREATE TABLE noticia (
  id_noticia INT PRIMARY KEY AUTO_INCREMENT,
  titulo VARCHAR(200) NOT NULL,
  fecha_publicacion DATETIME NOT NULL,
  id_categoria INT NOT NULL,
  autor VARCHAR(120),
  estado ENUM('borrador','publicada','archivada') NOT NULL DEFAULT 'publicada',
  CONSTRAINT fk_noticia_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  INDEX idx_noticia_categoria (id_categoria),
  INDEX idx_noticia_fecha (fecha_publicacion)
) ENGINE=InnoDB;

-- ========================================================
-- 3) Tabla de hechos (interacciones)
-- ========================================================

-- Tabla: Visita
CREATE TABLE visita (
  id_visita BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  id_noticia INT NOT NULL,
  id_dispositivo INT NOT NULL,
  fecha_visita DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tiempo_lectura_seg INT UNSIGNED,
  fuente_trafico ENUM('directo','buscador','red_social','referido','newsletter','otro') DEFAULT 'directo',
  CONSTRAINT fk_visita_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_visita_noticia
    FOREIGN KEY (id_noticia) REFERENCES noticia(id_noticia)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_visita_dispositivo
    FOREIGN KEY (id_dispositivo) REFERENCES dispositivo(id_dispositivo)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  INDEX idx_visita_usuario_fecha (id_usuario, fecha_visita),
  INDEX idx_visita_noticia_fecha (id_noticia, fecha_visita),
  INDEX idx_visita_dispositivo_fecha (id_dispositivo, fecha_visita)
) ENGINE=InnoDB;

-- ========================================================
-- 4) Vistas analíticas
-- ========================================================

-- Vista: audiencia diaria
CREATE OR REPLACE VIEW v_audiencia_diaria AS
SELECT
  DATE(fecha_visita) AS fecha,
  COUNT(*) AS total_visitas,
  COUNT(DISTINCT id_usuario) AS usuarios_unicos
FROM visita
GROUP BY DATE(fecha_visita);

-- Vista: noticias más visitadas
CREATE OR REPLACE VIEW v_top_noticias AS
SELECT
  n.id_noticia,
  n.titulo,
  c.nombre_categoria,
  COUNT(v.id_visita) AS visitas
FROM noticia n
JOIN categoria c ON c.id_categoria = n.id_categoria
LEFT JOIN visita v ON v.id_noticia = n.id_noticia
GROUP BY n.id_noticia, n.titulo, c.nombre_categoria
ORDER BY visitas DESC;

-- ========================================================
-- Fin del script
-- ========================================================