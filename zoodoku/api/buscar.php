<?php
// buscar.php?q=leo (GET)
// Devuelve hasta 8 animales cuyo nombre contenga el texto buscado.
//
// Respuesta: [ { "id": 1, "nombre": "León", "clase": "mamifero" }, ... ]

require_once 'conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Método no permitido.', 405);
}

// Texto que escribió el jugador (sin espacios al principio ni al final)
$texto = trim($_GET['q'] ?? '');

// Con menos de 2 letras salen demasiados resultados
if (mb_strlen($texto) < 2) {
    responder_json([]);
}

// Si el texto lleva % o _ hay que escaparlos (con !) para que LIKE
// los trate como letras normales y no como comodines
$texto = str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $texto);

try {
    $conexion = conectar();

    $consulta = $conexion->prepare(
        'SELECT id, nombre, clase
         FROM animales
         WHERE nombre LIKE :texto ESCAPE \'!\'
         ORDER BY nombre
         LIMIT 8'
    );
    $consulta->execute([':texto' => '%' . $texto . '%']);

    $animales = $consulta->fetchAll();
    foreach ($animales as &$animal) {
        $animal['id'] = (int) $animal['id'];
    }
    unset($animal);

    responder_json($animales);
} catch (PDOException $error) {
    responder_error('No se pudo buscar.', 500);
}
