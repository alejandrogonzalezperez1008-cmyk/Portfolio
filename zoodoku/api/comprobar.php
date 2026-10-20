<?php
// comprobar.php (POST)
// Comprueba si un animal vale para una casilla del tablero.
//
// Recibe (JSON):  { "tablero_id": 1, "celda": 4, "animal_id": 12, "jugador": "abc-123..." }
// Responde:       { "valido": true, "nombre": "León", "rareza": 12.5 }
//              o  { "valido": false, "motivo": "no_cumple" }
//
// Motivos de fallo: no_cumple, repetido, ocupada

require_once 'conexion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Método no permitido.', 405);
}

// ---------- 1. Leer y validar lo que manda el navegador ----------
$datos = leer_cuerpo_json();

$tablero_id = filter_var($datos['tablero_id'] ?? null, FILTER_VALIDATE_INT);
$celda      = filter_var($datos['celda'] ?? null, FILTER_VALIDATE_INT, [
    'options' => ['min_range' => 0, 'max_range' => 8],
]);
$animal_id  = filter_var($datos['animal_id'] ?? null, FILTER_VALIDATE_INT);
$jugador    = $datos['jugador'] ?? '';

// Ojo: la celda 0 es válida, por eso comparo con false y no uso empty()
if ($tablero_id === false || $celda === false || $animal_id === false) {
    responder_error('Faltan datos o no son correctos.');
}
if (!preg_match('/^[A-Za-z0-9-]{8,40}$/', $jugador)) {
    responder_error('Identificador de jugador no válido.');
}

try {
    $conexion = conectar();

    // ---------- 2. Sacar del servidor los criterios de la casilla ----------
    // No me fío de lo que diga el navegador: la fila y la columna salen del tablero
    $consulta = $conexion->prepare('SELECT * FROM tableros WHERE id = :id');
    $consulta->bindValue(':id', $tablero_id, PDO::PARAM_INT);
    $consulta->execute();
    $tablero = $consulta->fetch();

    if ($tablero === false) {
        responder_error('El tablero no existe.', 404);
    }

    $numero_fila = intdiv($celda, 3);   // 0, 1 o 2
    $numero_columna = $celda % 3;       // 0, 1 o 2
    $criterio_fila = $tablero['fila' . ($numero_fila + 1)];
    $criterio_columna = $tablero['col' . ($numero_columna + 1)];

    // ---------- 3. Reglas del juego ----------
    // a) Esa casilla no puede estar ya contestada por este jugador
    if (jugador_ya_respondio_celda($conexion, $tablero_id, $celda, $jugador)) {
        responder_json(['valido' => false, 'motivo' => 'ocupada']);
    }

    // b) No se puede usar el mismo animal dos veces en un tablero
    if (jugador_ya_uso_animal($conexion, $tablero_id, $animal_id, $jugador)) {
        responder_json(['valido' => false, 'motivo' => 'repetido']);
    }

    // c) El animal tiene que cumplir los dos criterios
    if (!animal_cumple($conexion, $animal_id, $criterio_fila, $criterio_columna)) {
        responder_json(['valido' => false, 'motivo' => 'no_cumple']);
    }

    // ---------- 4. Guardar el acierto y calcular la rareza ----------
    $insertar = $conexion->prepare(
        'INSERT INTO respuestas (tablero_id, celda, animal_id, jugador)
         VALUES (:tablero, :celda, :animal, :jugador)'
    );
    $insertar->bindValue(':tablero', $tablero_id, PDO::PARAM_INT);
    $insertar->bindValue(':celda', $celda, PDO::PARAM_INT);
    $insertar->bindValue(':animal', $animal_id, PDO::PARAM_INT);
    $insertar->bindValue(':jugador', $jugador);
    $insertar->execute();

    responder_json([
        'valido' => true,
        'nombre' => nombre_del_animal($conexion, $animal_id),
        'rareza' => rareza_de_la_respuesta($conexion, $tablero_id, $celda, $animal_id),
    ]);
} catch (PDOException $error) {
    responder_error('No se pudo comprobar la respuesta.', 500);
}


// ---------- Funciones ----------

function jugador_ya_respondio_celda($conexion, $tablero_id, $celda, $jugador)
{
    $consulta = $conexion->prepare(
        'SELECT COUNT(*) FROM respuestas
         WHERE tablero_id = :tablero AND celda = :celda AND jugador = :jugador'
    );
    $consulta->bindValue(':tablero', $tablero_id, PDO::PARAM_INT);
    $consulta->bindValue(':celda', $celda, PDO::PARAM_INT);
    $consulta->bindValue(':jugador', $jugador);
    $consulta->execute();
    return $consulta->fetchColumn() > 0;
}

function jugador_ya_uso_animal($conexion, $tablero_id, $animal_id, $jugador)
{
    $consulta = $conexion->prepare(
        'SELECT COUNT(*) FROM respuestas
         WHERE tablero_id = :tablero AND animal_id = :animal AND jugador = :jugador'
    );
    $consulta->bindValue(':tablero', $tablero_id, PDO::PARAM_INT);
    $consulta->bindValue(':animal', $animal_id, PDO::PARAM_INT);
    $consulta->bindValue(':jugador', $jugador);
    $consulta->execute();
    return $consulta->fetchColumn() > 0;
}

// El animal cumple los dos criterios si aparece 2 veces en la vista
// (una por cada criterio)
function animal_cumple($conexion, $animal_id, $criterio_fila, $criterio_columna)
{
    $consulta = $conexion->prepare(
        'SELECT COUNT(*) FROM v_animal_criterio
         WHERE animal_id = :animal AND criterio_id IN (:fila, :columna)'
    );
    $consulta->bindValue(':animal', $animal_id, PDO::PARAM_INT);
    $consulta->bindValue(':fila', $criterio_fila, PDO::PARAM_INT);
    $consulta->bindValue(':columna', $criterio_columna, PDO::PARAM_INT);
    $consulta->execute();
    return $consulta->fetchColumn() == 2;
}

function nombre_del_animal($conexion, $animal_id)
{
    $consulta = $conexion->prepare('SELECT nombre FROM animales WHERE id = :id');
    $consulta->execute([':id' => $animal_id]);
    return $consulta->fetchColumn();
}

// Porcentaje de jugadores que eligieron este mismo animal en esta casilla
function rareza_de_la_respuesta($conexion, $tablero_id, $celda, $animal_id)
{
    $consulta = $conexion->prepare(
        'SELECT porcentaje FROM v_rareza
         WHERE tablero_id = :tablero AND celda = :celda AND animal_id = :animal'
    );
    $consulta->bindValue(':tablero', $tablero_id, PDO::PARAM_INT);
    $consulta->bindValue(':celda', $celda, PDO::PARAM_INT);
    $consulta->bindValue(':animal', $animal_id, PDO::PARAM_INT);
    $consulta->execute();
    return (float) $consulta->fetchColumn();
}
