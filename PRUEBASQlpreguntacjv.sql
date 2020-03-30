-- pregunta 1

SELECT COUNT(t.curso_curso_id) as "evaluaciones por curso",   c.nombre
FROM test t
JOIN curso c
on t.curso_curso_id= c.curso_id
GROUP BY  c.nombre
;

--pregunta 2

SELECT c.nombre
FROM curso c
FULL JOIN test t ON c.curso_id=t.curso_curso_id
FULL JOIN prueba_individual p ON p.test_test_id=t.test_id
GROUP BY c.nombre
HAVING COUNT(p.prueba_individual_id)<1
;



--3. Pregunta 3: Determinar las evaluaciones con deficiencia. Una evaluación es deficiente:  

-- a. Si no tiene preguntas.

SELECT t.titulo_test, c.nombre
FROM test t
FULL JOIN preguntas p ON t.test_id= p.test_test_id
INNER JOIN curso c ON t.curso_curso_id=c.curso_id 
GROUP BY t.titulo_test, c.nombre
HAVING COUNT(p.preguntas_id)<1
;

--b. Si hay preguntas con 2 ó menos alternativas

SELECT  p.preguntas_id AS "numero pregunta" , t.titulo_test AS "titulo test", c.nombre AS "Curso"
from test t
RIGHT JOIN preguntas p ON t.test_id=p.test_test_id
RIGHT JOIN alternativas a ON p.preguntas_id=a.preguntas_preguntas_id
INNER JOIN curso c ON c.curso_id=t.curso_curso_id
GROUP BY  p.preguntas_id, t.titulo_test, c.nombre
HAVING COUNT(a.altenativas)<3
;

--c. Si todas las alternativas son correctas o si todas las alternativas son incorrectas.

SELECT p.preguntas_id AS "numero pregunta" , t.titulo_test AS "titulo test", c.nombre AS "Curso"
FROM test t
RIGHT JOIN preguntas p ON t.test_id=p.test_test_id
RIGHT JOIN alternativas a ON p.preguntas_id=a.preguntas_preguntas_id
INNER JOIN curso c ON c.curso_id=t.curso_curso_id
GROUP BY  p.preguntas_id, t.titulo_test, c.nombre
HAVING SUM(a.puntaje_pregunta)=0

-- Pregunta 4: Determinar cuántos alumnos hay en cada curso.

SELECT COUNT(a.nombre), c.nombre
FROM alumno a
INNER JOIN prueba_individual p ON a.alumno_id=p.alumno_alumno_id
INNER JOIN test t ON t.test_id=p.test_test_id
INNER JOIN curso c ON t.curso_curso_id=c.curso_id
GROUP BY c.nombre
;

--  pregunta 5

SELECT c.pru_ind, (c.correct- NVL(w.incorrect,0)/4) AS point,  
FROM(  
    SELECT p.prueba_individual_id AS pru_ind, c.correct as correct
    FROM prueba_individual p
    FULL JOIN (
    SELECT pru_ind, COUNT(correct_answer) AS correct
    FROM(
        SELECT r.pru_ind_prueba_individual_id AS pru_ind, count(r.pru_ind_prueba_individual_id) as correct_answer
        FROM respuestas_alumno r
        FULL JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
        WHERE r.respuesta_alumno=a.puntaje_pregunta
        GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
        HAVING count(r.preguntas_preguntas_id)=3
        ORDER BY r.pru_ind_prueba_individual_id)
    GROUP BY pru_ind
    ) c ON p.prueba_individual_id= c.pru_ind) c
LEFT JOIN ( 
        SELECT w.pru_ind, (w.wrong- NVL(n.not_answered, 0)) AS incorrect
        FROM(  
            SELECT pru_ind, COUNT(wrong_answer) AS wrong
            FROM(
                SELECT r.pru_ind_prueba_individual_id AS pru_ind ,r.preguntas_preguntas_id AS wrong_answer
                FROM respuestas_alumno r
                FULL JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
                WHERE r.respuesta_alumno<>a.puntaje_pregunta    
                GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
                ORDER BY r.pru_ind_prueba_individual_id)
            GROUP BY  pru_ind) w 
        left JOIN(
                SELECT pru_ind, count(not_answered) as not_answered
                FROM(
                    SELECT r.pru_ind_prueba_individual_id AS pru_ind ,r.preguntas_preguntas_id as not_answered
                    FROM respuestas_alumno r
                    INNER JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
                    GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
                    HAVING SUM(r.respuesta_alumno)=0
                    ) 
                GROUP BY pru_ind) n  ON w.pru_ind=n.pru_ind) w ON c.pru_ind=w.pru_ind
ORDER BY c.pru_ind
    
;
-- pregunta 6
-- se crea funcion para calcular nota final

create or replace FUNCTION final_score( final_point IN number, total_point IN number)
RETURN number
IS score number;
BEGIN
    IF final_point <= total_point*0.6 THEN
        score:= 1+ final_point*0.5;
    ELSE
        score:= 4+(final_point-total_point*0.6)*0.75;
    END IF;
RETURN score;
END;


SELECT c.pru_ind, final_score((c.correct- NVL(w.incorrect,0)/4), t.tot_point) as notas
FROM(  
    SELECT p.prueba_individual_id AS pru_ind, c.correct as correct
    FROM prueba_individual p
    FULL JOIN (
    SELECT pru_ind, COUNT(correct_answer) AS correct
    FROM(
        SELECT r.pru_ind_prueba_individual_id AS pru_ind, count(r.pru_ind_prueba_individual_id) as correct_answer
        FROM respuestas_alumno r
        FULL JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
        WHERE r.respuesta_alumno=a.puntaje_pregunta
        GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
        HAVING count(r.preguntas_preguntas_id)=3
        ORDER BY r.pru_ind_prueba_individual_id)
    GROUP BY pru_ind
    ) c ON p.prueba_individual_id= c.pru_ind) c
LEFT JOIN ( 
        SELECT w.pru_ind, (w.wrong- NVL(n.not_answered, 0)) AS incorrect
        FROM(  
            SELECT pru_ind, COUNT(wrong_answer) AS wrong
            FROM(
                SELECT r.pru_ind_prueba_individual_id AS pru_ind ,r.preguntas_preguntas_id AS wrong_answer
                FROM respuestas_alumno r
                FULL JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
                WHERE r.respuesta_alumno<>a.puntaje_pregunta    
                GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
                ORDER BY r.pru_ind_prueba_individual_id)
            GROUP BY  pru_ind) w 
        left JOIN(
                SELECT pru_ind, count(not_answered) as not_answered
                FROM(
                    SELECT r.pru_ind_prueba_individual_id AS pru_ind ,r.preguntas_preguntas_id as not_answered
                    FROM respuestas_alumno r
                    INNER JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
                    GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
                    HAVING SUM(r.respuesta_alumno)=0
                    ) 
                GROUP BY pru_ind) n  ON w.pru_ind=n.pru_ind) w ON c.pru_ind=w.pru_ind 

INNER JOIN (
            SELECT pru_ind_prueba_individual_id, count(preguntas_preguntas_id) AS tot_point
            FROM(  
                SELECT pru_ind_prueba_individual_id, preguntas_preguntas_id
                FROM respuestas_alumno
                GROUP BY pru_ind_prueba_individual_id, preguntas_preguntas_id)
            GROUP BY pru_ind_prueba_individual_id) t ON c.pru_ind = t. pru_ind_prueba_individual_id

;

--pregunta 7 

-- se crea una view con los puntaje del query de la pregunta 6, para hecer las siguientes queries  mas faciles de hacer

CREATE VIEW notas_alumnos AS
SELECT c.pru_ind, final_score((c.correct- NVL(w.incorrect,0)/4), t.tot_point) as notas
FROM(  
    SELECT p.prueba_individual_id AS pru_ind, c.correct as correct
    FROM prueba_individual p
    FULL JOIN (
    SELECT pru_ind, COUNT(correct_answer) AS correct
    FROM(
        SELECT r.pru_ind_prueba_individual_id AS pru_ind, count(r.pru_ind_prueba_individual_id) as correct_answer
        FROM respuestas_alumno r
        FULL JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
        WHERE r.respuesta_alumno=a.puntaje_pregunta
        GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
        HAVING count(r.preguntas_preguntas_id)=3
        ORDER BY r.pru_ind_prueba_individual_id)
    GROUP BY pru_ind
    ) c ON p.prueba_individual_id= c.pru_ind) c
LEFT JOIN ( 
        SELECT w.pru_ind, (w.wrong- NVL(n.not_answered, 0)) AS incorrect
        FROM(  
            SELECT pru_ind, COUNT(wrong_answer) AS wrong
            FROM(
                SELECT r.pru_ind_prueba_individual_id AS pru_ind ,r.preguntas_preguntas_id AS wrong_answer
                FROM respuestas_alumno r
                FULL JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
                WHERE r.respuesta_alumno<>a.puntaje_pregunta    
                GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
                ORDER BY r.pru_ind_prueba_individual_id)
            GROUP BY  pru_ind) w 
        left JOIN(
                SELECT pru_ind, count(not_answered) as not_answered
                FROM(
                    SELECT r.pru_ind_prueba_individual_id AS pru_ind ,r.preguntas_preguntas_id as not_answered
                    FROM respuestas_alumno r
                    INNER JOIN alternativas a ON  r.alternativa_id=a.alternativa_id
                    GROUP BY r.pru_ind_prueba_individual_id, r.preguntas_preguntas_id
                    HAVING SUM(r.respuesta_alumno)=0
                    ) 
                GROUP BY pru_ind) n  ON w.pru_ind=n.pru_ind) w ON c.pru_ind=w.pru_ind 

INNER JOIN (
            SELECT pru_ind_prueba_individual_id, count(preguntas_preguntas_id) AS tot_point
            FROM(  
                SELECT pru_ind_prueba_individual_id, preguntas_preguntas_id
                FROM respuestas_alumno
                GROUP BY pru_ind_prueba_individual_id, preguntas_preguntas_id)
            GROUP BY pru_ind_prueba_individual_id) t ON c.pru_ind = t. pru_ind_prueba_individual_id

;

SELECT a.nombre, c.nombre, t.titulo_test, n.notas
FROM notas_alumnos n
INNER JOIN prueba_individual p on n.pru_ind=p.prueba_individual_id
INNER JOIN alumno a ON a.alumno_id= p.alumno_alumno_id
INNER JOIN test t ON p.test_test_id=t.test_id
INNER JOIN curso c ON t.curso_curso_id= c.curso_id
; 

-- pregunta 8
SELECT c.nombre, t.titulo_test, AVG(n.notas)
FROM notas_alumnos n
INNER JOIN prueba_individual p on n.pru_ind=p.prueba_individual_id
INNER JOIN test t ON p.test_test_id=t.test_id
INNER JOIN curso c ON t.curso_curso_id= c.curso_id
GROUP BY c.nombre, t.titulo_test







 






