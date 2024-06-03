/*---------- CREACION DE LA BBDD ------------------*/

DROP DATABASE educacion;
CREATE DATABASE educacion;
USE educacion;

CREATE TABLE docente(
    id_docente INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50),
    correo VARCHAR(50),
    telefono VARCHAR(20),
    dni INT,
    usuario VARCHAR(50),
    contrasena VARCHAR(50)
);

CREATE TABLE carrera(
        id_carrera INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        carrera VARCHAR(50)
);
CREATE TABLE sede(
        id_sede INT NOT NULL PRIMARY KEY,
        sede VARCHAR(50)
);
CREATE TABLE turno(
        id_turno INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        dias VARCHAR(50),
        turno VARCHAR(50),
        horario VARCHAR(50)
);
CREATE TABLE estudiante(
        id_estudiante INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50),
        correo VARCHAR(50),
        telefono VARCHAR(20),
        dni INT,
        usuario VARCHAR(50),
        contrasena VARCHAR(50),
        id_carrera INT NOT NULL,
        FOREIGN KEY (id_carrera) REFERENCES carrera(id_carrera)
);
CREATE TABLE materia(
        id_materia INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        materia VARCHAR(50)
);
CREATE TABLE aula(
        id_aula INT NOT NULL PRIMARY KEY,
        id_sede INT NOT NULL,
        FOREIGN KEY (id_sede) REFERENCES sede(id_sede)
);
CREATE TABLE comision(
        id_comision INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        id_docente INT NOT NULL,
        id_materia INT NOT NULL,
        id_sede INT NOT NULL,
        id_aula INT NOT NULL,
        id_turno INT NOT NULL,
        FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
        FOREIGN KEY (id_materia) REFERENCES materia(id_materia),
        FOREIGN KEY (id_sede) REFERENCES sede(id_sede),
        FOREIGN KEY (id_aula) REFERENCES aula(id_aula),
        FOREIGN KEY (id_turno) REFERENCES turno(id_turno)
);
CREATE TABLE calificacion(
        id_calificacion INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        calificacion INT,
        id_estudiante INT NOT NULL,
        id_materia INT NOT NULL,
        id_carrera INT NOT NULL,
        id_comision INT NOT NULL,
        fecha DATE,
        FOREIGN KEY (id_estudiante) REFERENCES estudiante(id_estudiante),
        FOREIGN KEY (id_materia) REFERENCES materia(id_materia),
        FOREIGN KEY (id_carrera) REFERENCES carrera(id_carrera),
        FOREIGN KEY (id_comision) REFERENCES comision(id_comision)
);

CREATE TABLE inscripcion(
        id_inscripcion INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        id_estudiante INT NOT NULL,
        id_materia INT NOT NULL,
        id_comision INT NOT NULL,
        FOREIGN KEY (id_estudiante) REFERENCES estudiante(id_estudiante),
        FOREIGN KEY (id_materia) REFERENCES materia(id_materia),
        FOREIGN KEY (id_comision) REFERENCES comision(id_comision)
);
CREATE TABLE rel_carrera_materia(
        id_carrera INT NOT NULL,
        id_materia INT NOT NULL,
        FOREIGN KEY (id_carrera) REFERENCES carrera(id_carrera),
        FOREIGN KEY (id_materia) REFERENCES materia(id_materia)
);

/*----------------------------- INSERCION DE DATOS -------------------------------*/
INSERT INTO sede (id_sede, sede) VALUES
    (1, 'Haedo'),
    (2, 'CABA'),
    (3, 'Moreno');

-- Importar datos de carrera (8 datos)
-- Importar datos de turno (8 datos)
-- Importar datos de materia (199 datos)
-- Importar datos de estudiante (700 datos)
-- Importar datos de aula (55 datos)
-- Importar datos de comision (300 datos)
-- Importar datos de rel_carrera_materia (319 datos)
-- Importar datos de calificacion (16 datos)

/*
SELECT * FROM docente;
SELECT * FROM carrera;
SELECT * FROM turno;
SELECT * FROM materia;
SELECT * FROM estudiante;
SELECT * FROM aula;
SELECT * FROM comision;
SELECT * FROM rel_carrera_materia;
SELECT * FROM sede;
SELECT * FROM calificacion;
*/

/*-------------------------------------------- VISTAS ---------------------------------------------*/
CREATE OR REPLACE VIEW datos_docente AS
SELECT 
    id_docente, 
    nombre, 
    correo, 
    telefono, 
    dni
FROM docente;
--
CREATE OR REPLACE VIEW datos_estudiante AS
SELECT e.id_estudiante, 
       e.nombre, 
       e.correo, 
       e.telefono, 
	   e.dni, 
       c.carrera 
FROM estudiante AS e
INNER JOIN carrera AS c ON e.id_carrera = c.id_carrera;

--
CREATE OR REPLACE VIEW calificaciones_estudiantes AS
SELECT 
    e.nombre AS nombre_estudiante, 
    m.materia, 
    c.calificacion
FROM 
    estudiante e
JOIN 
    calificacion c ON e.id_estudiante = c.id_estudiante
JOIN 
    materia m ON c.id_materia = m.id_materia;
    
--
CREATE OR REPLACE VIEW  comisiones_cursos AS
SELECT 
    c.id_comision,
    d.nombre AS docente,
    m.materia,
    s.sede,
    a.id_aula AS aula,
    t.dias,
    t.turno
FROM 
    comision c
INNER JOIN 
    docente d ON c.id_docente = d.id_docente
INNER JOIN 
    materia m ON c.id_materia = m.id_materia
INNER JOIN 
    sede s ON c.id_sede = s.id_sede
INNER JOIN 
    aula a ON c.id_aula = a.id_aula
INNER JOIN 
    turno t ON c.id_turno = t.id_turno;
--
/*
SELECT * FROM datos_docente;
SELECT * FROM datos_estudiante;
SELECT * FROM calificaciones_estudiantes;
SELECT * FROM comisiones_cursos;

*/

/* --------------------------------- PROMEDIO ALUMNOS -----------------------------------------*/

ALTER TABLE estudiante
ADD COLUMN promedio_calificaciones FLOAT;

-- función para calcular el promedio de calificaciones
DELIMITER %%

CREATE FUNCTION calcular_promedio_estudiante(id_estudiante INT)
RETURNS FLOAT
READS SQL DATA
BEGIN
    DECLARE avg_calificacion FLOAT;
    
    SELECT AVG(calificacion) INTO avg_calificacion 
    FROM calificacion 
    WHERE id_estudiante = id_estudiante;
    
    RETURN avg_calificacion;
END %%
-- Procedimiento almacenado para actualizar el promedio de calificaciones
DELIMITER %%

CREATE PROCEDURE actualizar_promedio_estudiante(IN estudiante_id INT)
BEGIN
    DECLARE avg_promedio FLOAT;
    
    SET avg_promedio = calcular_promedio_estudiante(estudiante_id);
    
    UPDATE estudiante 
    SET promedio_calificaciones = avg_promedio 
    WHERE id_estudiante = estudiante_id;
END %%

DELIMITER ;
-- Trigger para actualizar automáticamente el promedio de calificaciones 
DELIMITER %%

CREATE TRIGGER trigger_actualizar_promedio AFTER INSERT ON calificacion
FOR EACH ROW
BEGIN
    
    CALL actualizar_promedio_estudiante(NEW.id_estudiante);
END;
%%
DELIMITER ;
/*
SELECT calcular_promedio_estudiante(84);

INSERT INTO calificacion (calificacion, id_estudiante, id_materia, id_carrera, id_comision, fecha)
VALUES (8, 84, 72, 7, 100, '2024-05-03');

SELECT * FROM calificacion c WHERE c.id_estudiante = 84;
SELECT calcular_promedio_estudiante(84);
DELETE FROM calificacion WHERE id_calificacion = 17;
*/


/* ---------------------------- INSCRIPCION ALUMNOS --------------------------------------- */
-- Procedimiento para inscribir a un alumno en una materia
DROP PROCEDURE IF EXISTS inscribir_alumno;
DELIMITER %%
CREATE PROCEDURE inscribir_alumno(
    IN estudiante_nombre VARCHAR(50),
    IN materia_nombre VARCHAR(50),
    IN comision_id INT
)
BEGIN
    DECLARE estudiante_id INT;
    DECLARE materia_id INT;
    DECLARE corresponde BOOLEAN;
    DECLARE calif INT;

    SELECT id_estudiante INTO estudiante_id FROM estudiante WHERE nombre = estudiante_nombre;

    SELECT id_materia INTO materia_id FROM materia WHERE materia = materia_nombre;

    SELECT COUNT(*) INTO corresponde
    FROM rel_carrera_materia
    WHERE id_materia = materia_id
    AND id_carrera = (SELECT id_carrera FROM estudiante WHERE id_estudiante = estudiante_id);

    IF corresponde THEN
        SELECT calificacion INTO calif
        FROM calificacion
        WHERE id_estudiante = estudiante_id AND id_materia = materia_id;

        IF calif IS NULL OR calif < 4 THEN
            INSERT INTO inscripcion (id_estudiante, id_materia, id_comision)
            VALUES (estudiante_id, materia_id, comision_id);
            SELECT 'Alumno inscripto correctamente.' AS mensaje;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede inscribir, la materia está aprobada';

        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede inscribir, la materia no corresponde a la carrera del estudiante';
    END IF;
END %%

DELIMITER ;

/*
SELECT * FROM calificacion;
SELECT * FROM estudiante;
SELECT * FROM materia;
SELECT * FROM carrera;
SELECT * FROM rel_carrera_materia;

 -- prueba 
CALL inscribir_alumno('Falito Dawtre', 'Quimica inorganica', 10); (si se puede)
CALL inscribir_alumno('Falito Dawtre', 'Aeronautica I', 15); (no se puede)
CALL inscribir_alumno('Anselma Firpi', 'Economia', 1);
SELECT * FROM inscripcion;
DELETE FROM inscripcion i WHERE i.id_inscripcion = 1;
*/

/* Lleno la tabla de inscripcion para hacer un reporte  ---------------------------------*/

CALL inscribir_alumno('Falito Dawtre', 'Quimica inorganica', 10);
CALL inscribir_alumno('Anselma Firpi', 'Economia', 1);
CALL inscribir_alumno('Teddie Peron', 'Ingenieria y sociedad', 20);
CALL inscribir_alumno('Blayne Middlemist', 'Ingles I', 2);
CALL inscribir_alumno('Arliene Murrish', 'Probabilidad y estadistica', 13);
CALL inscribir_alumno('Tish Loudwell', 'Fisica I', 15);
CALL inscribir_alumno('Gabrila Corney', 'Algebra y geometria analitica', 9);
CALL inscribir_alumno('Ermentrude McCreery', 'Ingenieria y sociedad', 8);
CALL inscribir_alumno('Chanda Delleschi', 'Quimica general', 9);
CALL inscribir_alumno('Mike Tureville', 'Ingles II', 12);
CALL inscribir_alumno('Mike Tureville', 'Electiva', 21);
CALL inscribir_alumno('Kimbra Labell', 'Practica supervisada', 3);
CALL inscribir_alumno('Scotty Tapley', 'Analisis matematico I', 4);
CALL inscribir_alumno('Stacia Gepheart', 'Economia', 4);
CALL inscribir_alumno('Isak Guys', 'Computacion', 3);
CALL inscribir_alumno('Ches Massei', 'Quimica general', 1);
CALL inscribir_alumno('Harcourt Garshore', 'Analisis matematico I', 17);
CALL inscribir_alumno('Kev Keighly', 'Fisica II', 12);
CALL inscribir_alumno('Lauren Bonifant', 'Analisis matematico I', 18);
CALL inscribir_alumno('Anselma Firpi', 'Practica supervisada', 4);
CALL inscribir_alumno('Ches Massei', 'Quimica general', 1);
CALL inscribir_alumno('Ashil Leehane', 'Analisis matematico I', 17);
CALL inscribir_alumno('Kev Keighly', 'Fisica II', 12);
CALL inscribir_alumno('Merrill Gaynor', 'Quimica general', 18);

-- SELECT * FROM inscripcion;

/* -------------------------- BUSCAR ESTUDIANTES POR NOMBRE ------------------------------------*/
DROP FUNCTION IF EXISTS buscar_estudiante_por_nombre;
DELIMITER %%
CREATE FUNCTION buscar_estudiante_por_nombre(
    nombre_estudiante VARCHAR(50)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE estudiante_id INT;

    SELECT id_estudiante INTO estudiante_id
    FROM datos_estudiante
    WHERE nombre = nombre_estudiante;

    RETURN estudiante_id;
END %%
DELIMITER ;

-- SELECT buscar_estudiante_por_nombre('Falito Dawtre'); 



/* ---------------------------------- CALCULO ESTUDIANTES POR CARRERA -----------------------------------------*/
DROP PROCEDURE IF EXISTS estudiantes_por_carrera;

DELIMITER %%
CREATE PROCEDURE estudiantes_por_carrera()
BEGIN
    CREATE TABLE IF NOT EXISTS c_resultado (
        id_carrera INT,
        carrera VARCHAR(255),
        cantidad_estudiantes INT
    );

    INSERT INTO c_resultado
    SELECT c.id_carrera, c.carrera, COUNT(e.id_estudiante) AS cantidad_estudiantes
    FROM carrera c
    LEFT JOIN estudiante e ON c.id_carrera = e.id_carrera
    GROUP BY c.id_carrera, c.carrera
    ORDER BY c.id_carrera ASC; 

    SELECT * FROM c_resultado;

    DROP TABLE IF EXISTS c_resultado;
END%%

DELIMITER;

-- CALL estudiantes_por_carrera();

 
 
/*-------------------------------- HISTORIAL ACADEMICO --------------------------------------- */
DROP PROCEDURE IF EXISTS historial_academico;
DELIMITER %%

CREATE PROCEDURE historial_academico(
    IN estudiante_nombre VARCHAR(50)
)
BEGIN
    DECLARE estudiante_id INT;
    
    SELECT id_estudiante INTO estudiante_id
    FROM estudiante
    WHERE nombre = estudiante_nombre;
    
    SELECT c.id_comision, m.materia, ca.calificacion, ca.fecha
    FROM calificacion ca
    INNER JOIN comision c ON ca.id_comision = c.id_comision
    INNER JOIN materia m ON c.id_materia = m.id_materia
    WHERE ca.id_estudiante = estudiante_id
    ORDER BY ca.fecha ASC;
END %%
DELIMITER ;

-- CALL historial_academico('Falito Dawtre');

/* ---------------------------- ESTUDIANTES INSCRIPTOS EN UNA MATERIA-----------------------------------*/
DROP FUNCTION IF EXISTS inscriptos_materia;

DELIMITER $$

CREATE FUNCTION inscriptos_materia(
    materia_nombre VARCHAR(50)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE count_estudiantes INT;

    DECLARE materia_id INT;
    SELECT id_materia INTO materia_id FROM materia WHERE materia = materia_nombre;

    SELECT COUNT(*) INTO count_estudiantes
    FROM inscripcion
    WHERE id_materia = materia_id;

    RETURN count_estudiantes;
END $$

DELIMITER ;

-- SELECT inscriptos_materia('Quimica inorganica') AS total_estudiantes;
-- SELECT * FROM inscripcion;

/*--------------------- REGISTRO DE CAMBIOS EN LA TABLA DOCENTES */

CREATE TABLE docente_audit (
    id_docente_audit INT AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada VARCHAR(50),
    id_afectado INT,
    accion VARCHAR(10),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER registro_cambios_docente
AFTER INSERT ON docente
FOR EACH ROW
BEGIN
    INSERT INTO docente_audit (tabla_afectada, id_afectado, accion)
    VALUES ('docente', NEW.id_docente, 'INSERT');
END $$

DELIMITER ;

/*
INSERT INTO docente (nombre, correo, telefono, dni, usuario, contrasena) 
VALUES ('Juan Pérez', 'juan@example.com', '123456789', 12345678, 'juanperez', 'contraseña123');
SELECT * FROM docente_audit;
*/
