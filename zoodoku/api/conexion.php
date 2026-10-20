<?php
// conexion.php
// Funciones comunes que usan todos los archivos de la API:
// conectar a la base de datos y responder en formato JSON.

// Datos de conexión (los de XAMPP por defecto, cámbialos si hace falta)
const DB_SERVIDOR = 'localhost';
const DB_NOMBRE   = 'zoodoku';
const DB_USUARIO  = 'root';
const DB_CLAVE    = '';

// Devuelve la conexión PDO a la base de datos
function conectar()
{
    $dsn = 'mysql:host=' . DB_SERVIDOR . ';dbname=' . DB_NOMBRE . ';charset=utf8mb4';

    $conexion = new PDO($dsn, DB_USUARIO, DB_CLAVE);
    // Que PDO lance excepciones si una consulta falla
    $conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    // Que fetch() devuelva arrays asociativos por defecto
    $conexion->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    return $conexion;
}

// Envía los datos como JSON con el código HTTP indicado y termina el script
function responder_json($datos, $codigo = 200)
{
    http_response_code($codigo);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit;
}

// Para los errores: mensaje corto y código HTTP
function responder_error($mensaje, $codigo = 400)
{
    responder_json(['error' => $mensaje], $codigo);
}

// Lee el cuerpo de una petición POST que viene en JSON y lo devuelve como array
function leer_cuerpo_json()
{
    $texto = file_get_contents('php://input');
    $datos = json_decode($texto, true);

    if (!is_array($datos)) {
        responder_error('El cuerpo de la petición no es un JSON válido.');
    }
    return $datos;
}
