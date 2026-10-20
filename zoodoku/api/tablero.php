<?php
// tablero.php (GET)
// Devuelve el tablero de hoy. Si todavía no existe, lo crea.
//
// Respuesta:
// { "tablero_id": 1, "fecha": "2026-10-15",
//   "filas":    [ {"id": 3, "texto": "Mamífero", "icono": "🦁"}, ... ],
//   "columnas": [ {...}, {...}, {...} ] }

require_once 'conexion.php';

// Mínimo de animales que tiene que haber para cada casilla del tablero
const MINIMO_RESPUESTAS = 3;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Método no permitido.', 405);
}

try {
    $conexion = conectar();
    $fecha_hoy = date('Y-m-d');

    $tablero = buscar_tablero($conexion, $fecha_hoy);
    if ($tablero === false) {
        $tablero = crear_tablero($conexion, $fecha_hoy);
    }

    responder_json(preparar_respuesta($conexion, $tablero));
} catch (PDOException $error) {
    responder_error('No se pudo cargar el tablero.', 500);
}


// ---------- Funciones ----------

// Busca el tablero de una fecha. Devuelve false si no hay ninguno.
function buscar_tablero($conexion, $fecha)
{
    $consulta = $conexion->prepare('SELECT * FROM tableros WHERE fecha = :fecha');
    $consulta->execute([':fecha' => $fecha]);
    return $consulta->fetch();
}

// Crea el tablero de una fecha eligiendo 6 criterios al azar
// (3 para las filas y 3 para las columnas) de forma que todas las
// casillas tengan al menos MINIMO_RESPUESTAS animales posibles.
function crear_tablero($conexion, $fecha)
{
    // 1. Criterios activos
    $criterios = $conexion
        ->query('SELECT id FROM criterios WHERE activo = 1')
        ->fetchAll(PDO::FETCH_COLUMN);

    // 2. Parejas de criterios con animales suficientes en común.
    //    Las guardo en un array para consultarlas rápido: "3-12" => true
    $parejas_validas = [];
    $consulta = $conexion->prepare('SELECT criterio_a, criterio_b FROM v_parejas WHERE total >= :minimo');
    $consulta->bindValue(':minimo', MINIMO_RESPUESTAS, PDO::PARAM_INT);
    $consulta->execute();
    foreach ($consulta as $pareja) {
        $parejas_validas[$pareja['criterio_a'] . '-' . $pareja['criterio_b']] = true;
    }

    // 3. Mezclar y probar combinaciones hasta encontrar una buena.
    //    La semilla depende de la fecha para que el resultado sea siempre
    //    el mismo ese día aunque dos jugadores entren a la vez.
    mt_srand(crc32($fecha));
    $elegidos = null;

    for ($intento = 0; $intento < 2000; $intento++) {
        shuffle($criterios);
        $filas = array_slice($criterios, 0, 3);
        $columnas = array_slice($criterios, 3, 3);

        if (todas_las_casillas_tienen_respuesta($filas, $columnas, $parejas_validas)) {
            $elegidos = [$filas, $columnas];
            break;
        }
    }

    if ($elegidos === null) {
        throw new PDOException('No se encontró ningún tablero válido.');
    }

    // 4. Guardarlo. Si otro jugador lo creó justo antes, la fecha es UNIQUE
    //    y el INSERT falla: en ese caso leemos el que ya existe.
    try {
        $insertar = $conexion->prepare(
            'INSERT INTO tableros (fecha, fila1, fila2, fila3, col1, col2, col3)
             VALUES (:fecha, :f1, :f2, :f3, :c1, :c2, :c3)'
        );
        $insertar->execute([
            ':fecha' => $fecha,
            ':f1' => $elegidos[0][0], ':f2' => $elegidos[0][1], ':f3' => $elegidos[0][2],
            ':c1' => $elegidos[1][0], ':c2' => $elegidos[1][1], ':c3' => $elegidos[1][2],
        ]);
    } catch (PDOException $error) {
        $existente = buscar_tablero($conexion, $fecha);
        if ($existente === false) {
            throw $error;
        }
        return $existente;
    }

    return buscar_tablero($conexion, $fecha);
}

// Comprueba que cada fila combina bien con cada columna
function todas_las_casillas_tienen_respuesta($filas, $columnas, $parejas_validas)
{
    foreach ($filas as $fila) {
        foreach ($columnas as $columna) {
            if (!isset($parejas_validas[$fila . '-' . $columna])) {
                return false;
            }
        }
    }
    return true;
}

// Convierte la fila de la tabla tableros en lo que necesita el navegador
function preparar_respuesta($conexion, $tablero)
{
    $consulta = $conexion->prepare('SELECT id, texto, icono FROM criterios WHERE id = :id');

    $leer_criterio = function ($id) use ($consulta) {
        $consulta->execute([':id' => $id]);
        $criterio = $consulta->fetch();
        // El id viene como texto o número según el driver, lo pasamos a número
        $criterio['id'] = (int) $criterio['id'];
        return $criterio;
    };

    return [
        'tablero_id' => (int) $tablero['id'],
        'fecha'      => $tablero['fecha'],
        'filas'      => [
            $leer_criterio($tablero['fila1']),
            $leer_criterio($tablero['fila2']),
            $leer_criterio($tablero['fila3']),
        ],
        'columnas'   => [
            $leer_criterio($tablero['col1']),
            $leer_criterio($tablero['col2']),
            $leer_criterio($tablero['col3']),
        ],
    ];
}
