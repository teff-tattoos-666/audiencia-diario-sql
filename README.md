# Proyecto: Medición de Audiencia - El Cronista

Este repositorio contiene el **script SQL** y documentación asociada al proyecto de base de datos diseñado para la **medición de audiencia digital**.

---

## 📂 Contenido del repositorio

- `IdeaNovogrebelska.sql` → Script de creación de la base de datos y tablas.  
- `README.md` → Este archivo con instrucciones y descripción del proyecto.  
- (Opcional) `/img` → Diagramas de Entidad-Relación y esquemas.

---

## 🗄️ Descripción breve

La base de datos **medicion_audiencia** centraliza información sobre:
- Autores y artículos publicados.
- Usuarios y sus visitas.
- Dispositivos y canales de acceso.
- Campañas de newsletters o publicidad.

Con esta estructura se pueden generar reportes de tráfico, análisis de comportamiento y segmentación de la audiencia.

---

## ⚙️ Requisitos

- **MySQL Server** 8.0+ (se recomienda última versión).  
- **MySQL Workbench** para ejecutar y visualizar el modelo.  
- Conexión a una base de datos local o remota con permisos de creación.

---

## ▶️ Instrucciones de ejecución en MySQL Workbench

1. Abrir **MySQL Workbench** y conectarse al servidor local (o al servidor configurado).
2. Ir a **File > Open SQL Script…** y seleccionar `IdeaNovogrebelska.sql`.
3. Revisar el contenido del script (incluye la creación de la base `medicion_audiencia`).
4. Ejecutar todo el script presionando el ícono del rayo ⚡ ("Run all") o con `Ctrl+Shift+Enter`.
5. Confirmar que las tablas fueron creadas correctamente:
   ```sql
   USE medicion_audiencia;
   SHOW TABLES;
   ```
6. (Opcional) Insertar datos de prueba para validar relaciones y hacer consultas.

---

## 🧪 Ejemplo de consulta

Obtener los 10 artículos más leídos en un período:
```sql
SELECT a.art_titulo, COUNT(v.vis_id) AS visitas
FROM visita v
JOIN articulo a ON v.art_id = a.art_id
WHERE v.vis_timestamp BETWEEN '2025-01-01' AND '2025-01-31'
GROUP BY a.art_titulo
ORDER BY visitas DESC
LIMIT 10;
```

---

## 📊 Diagrama ER

El diagrama entidad-relación (EER) puede visualizarse importando el script en **MySQL Workbench** o consultando el archivo `/img/diagrama_ER.png` si está disponible.

---

## 👩‍💻 Autor

**Estefania Novogrebelska Mezger**  
Proyecto académico - SQL - 2025

---

## 📜 Licencia

Uso educativo y académico. Se permite la reutilización con fines de aprendizaje.
